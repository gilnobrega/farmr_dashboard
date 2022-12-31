
<?php

use Kreait\Firebase\Factory;
use Kreait\Firebase\Auth;

require __DIR__ . '/vendor/autoload.php';

header("Access-Control-Allow-Origin: *");
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
ini_set('max_execution_time', 300); //300 seconds = 5 minutes. In case if your CURL is slow and is loading too much (Can be IPv6 problem)
ini_set('memory_limit', '512M');

include_once 'oauth.php'; //initializes $conn = new mysqli();

error_reporting(E_ALL);

$authorizeURL = 'https://discord.com/api/oauth2/authorize';
$tokenURL = 'https://discord.com/api/oauth2/token';
$apiURLBase = 'https://discord.com/api/users/@me';

//saves session contents for 1 month
session_start([
  'cookie_lifetime' => 60 * 60 * 24 * 30,
  'gc_maxlifetime' => 60 * 60 * 24 * 30
]);
 if (get('action') == 'readCustomToken')
{
  echo $_SESSION['customToken'];
  unset($_SESSION['customToken']);
  die();
}

if (get('action') == "readconfig" && isset($_GET['id'])) {
  include('db.php'); //initializes $conn = new mysqli();

  $idEscaped = $conn->real_escape_string($_GET['id']);

  $command = " SELECT config FROM configs WHERE id='" . $idEscaped . "' LIMIT 1;";
  $result = $conn->query($command);
  $config = "{}";
  while ($row = $result->fetch_row()) {

    $config = $row[0];
  }

  echo $config;
} else if (isset($_POST['token']) ) {

  $data = array();
  $user = array();

  $factory = (new Factory)->withServiceAccount('../farmr-1cc6e-firebase-adminsdk-<firebasefile>.json');
  $auth = $factory->createAuth();

  $token = $_POST['token'];

  try {
    $verifiedIdToken = $auth->verifyIdToken($token);
  } catch (InvalidToken $e) {
    echo 'The token is invalid: ' . $e->getMessage();
    die();
  } catch (\InvalidArgumentException $e) {
    echo 'The token could not be parsed: ' . $e->getMessage();
    die();
  }

  // if you're using lcobucci/jwt ^4.0
  $uid = $verifiedIdToken->claims()->get('sub');

  $firebaseUser = $auth->getUser($uid);

  $user['username'] = $firebaseUser->displayName;
  $user['id'] = $uid;

  if (isset($firebaseUser->email))
    $user['id'] = $firebaseUser->email;

  $user['avatar'] = $firebaseUser->photoUrl;

  $data['user'] = $user;

  if (get('action') == "read") {

    $data['harvesters'] = array();

    include('db.php'); //initializes $conn = new mysqli();
    $userEscaped = $conn->real_escape_string($user['id']);

    $command = " SELECT id,data FROM farms WHERE user='" . $user['id'] . "' AND data<>'' AND data<>';;' ORDER BY lastUpdated DESC;";
    $result = $conn->query($command);

    while ($row = $result->fetch_row()) {
      $harvester = array();

      $harvester['id'] = $row[0];
      $harvester['data'] = json_decode($row[1]);

      array_push($data['harvesters'], $harvester);
    }

    echo json_encode($data);
  } else if (get('action') == "link" && isset($_GET['id'])) {
    include('db.php'); //initializes $conn = new mysqli();

    $idEscaped = $conn->real_escape_string($_GET['id']);

    $userEscaped = $conn->real_escape_string($user['id']);

    $command = "INSERT INTO farms (id, data, user) VALUES ('" . $idEscaped . "', ';;', '" . $userEscaped . "') ON DUPLICATE KEY UPDATE user=IF(user='none','" . $userEscaped . "', user)";
    $result = $conn->query($command);

    if ($result) {
      echo "success";
    }
  } else if (get('action') == "unlink" && isset($_GET['id'])) {
    include('db.php'); //initializes $conn = new mysqli();

    $idEscaped = $conn->real_escape_string($_GET['id']);
    $userEscaped = $conn->real_escape_string($user['id']);

    $command = "UPDATE farms SET user='none' WHERE user='" . $userEscaped . "' AND id='" . $idEscaped . "' LIMIT 1";
    $result = $conn->query($command);

    if ($result) {
      echo "success";
    }
  }
  //only able to save config if logged in
  else if (get('action') == "saveconfig" && isset($_GET['id']) && isset($_POST['data'])) {
    include('db.php'); //initializes $conn = new mysqli();

    $idEscaped = $conn->real_escape_string($_GET['id']);
    $dataEscaped = $conn->real_escape_string($_POST['data']);
    $userEscaped = $conn->real_escape_string($user['id']);

    $command = "SELECT id from farms WHERE id='" . $idEscaped . "' AND user='" . $userEscaped . "';";
    $result = $conn->query($command);

    if ($result->num_rows > 0) {

      $command = " INSERT INTO configs (id,config) VALUES ('" . $idEscaped . "','" . $dataEscaped . "') ON DUPLICATE KEY UPDATE config='" . $dataEscaped . "';";
      $result = $conn->query($command);

      if ($result) {
        echo "success";
      }
    }
  } else {
    //closes window and returns to dashboard
    echo "<script>
    //mobile
      // Simulate an HTTP redirect:
      window.location.replace('https://" . PREFIX . "farmr.net/index.html');     
    </script>";
  }
} else {
  echo '<h3>Not logged in</h3>';
  echo '<p><a href="?action=login">Log In</a></p>';
}


if (get('action') == 'logout') {
  unset($_SESSION['userID']);
  unset($_SESSION['avatar']);
  unset($_SESSION['username']);

  $revokeURL = 'https://discordapp.com/api/oauth2/token/revoke';

  apiRequest($revokeURL, array(
    'token' => session('access_token'),
    'client_id' => OAUTH2_CLIENT_ID,
    'client_secret' => OAUTH2_CLIENT_SECRET,
  ));
  unset($_SESSION['access_token']);

  session_destroy();

  die();
}

function get($key, $default = NULL)
{
  return array_key_exists($key, $_GET) ? $_GET[$key] : $default;
}

function session($key, $default = NULL)
{
  return array_key_exists($key, $_SESSION) ? $_SESSION[$key] : $default;
}


?>
