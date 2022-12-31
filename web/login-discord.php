<?php
header("Access-Control-Allow-Origin: *");
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('max_execution_time', 300); //300 seconds = 5 minutes. In case if your CURL is slow and is loading too much (Can be IPv6 problem)

include_once 'login.php';

use Kreait\Firebase\Factory;
use Kreait\Firebase\Auth;

// Start the login process by sending the user to Discord's authorization page
if (get('action') == 'login') {

  $params = array(
    'client_id' => OAUTH2_CLIENT_ID,
    'redirect_uri' => OAUTH2_REDIRECT_URI,
    'response_type' => 'code',
    'scope' => 'identify'
  );

  // Redirect the user to Discord's authorization page
  header('Location: https://discord.com/api/oauth2/authorize' . '?' . http_build_query($params));
  die();
}

// When Discord redirects the user back here, there will be a "code" and "state" parameter in the query string
if (get('code')) {

  // Exchange the auth code for a token
  $token = apiRequest($tokenURL, "", array(
    "grant_type" => "authorization_code",
    'client_id' => OAUTH2_CLIENT_ID,
    'client_secret' => OAUTH2_CLIENT_SECRET,
    //redirects user to dashboard
    'redirect_uri' => OAUTH2_REDIRECT_URI,
    'code' => get('code')
  ));

  $discordUser = apiRequest($apiURLBase, $token->access_token);

  $factory = (new Factory)->withServiceAccount('../farmr-1cc6e-firebase-adminsdk-<firebasefile>.json');
  $auth = $factory->createAuth();

  //checks if user exists
  try {
    $user = $auth->getUser($discordUser->id);
  } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $e) {
    //creates user if it doesnt
    $userProperties = [
      'uid' => $discordUser->id,
      'displayName' => $discordUser->username,
      'photoUrl' => "https://cdn.discordapp.com/avatars/" . $discordUser->id . "/" . $discordUser->avatar . $discordUser->avatar . ".png",
      'disabled' => false,
      'emailVerified' => true
    ];

    $user = $auth->createUser($userProperties);
  }

  $properties = [
    'displayName' => $discordUser->username,
    'photoUrl' => "https://cdn.discordapp.com/avatars/" . $discordUser->id . "/" . $discordUser->avatar . ".png",
  ];

  $updatedUser = $auth->updateUser($discordUser->id, $properties);

  $customToken = $auth->createCustomToken($discordUser->id);

  $_SESSION['customToken'] = $customToken->toString();

  //closes window and returns to dashboard
  echo "<script>
      //mobile
        // Simulate an HTTP redirect:
        window.location.replace('https://" . PREFIX . "farmr.net/index.html');     
      </script>";
}

function apiRequest($url, $token, $post = FALSE, $headers = array())
{
  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

  $response = curl_exec($ch);


  if ($post) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($post));


    $headers[] = 'Accept: application/json';
  } else {

    $headers[] = 'Authorization: Bearer ' . $token;
  }

  curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

  $response = curl_exec($ch);
  return json_decode($response);
}
