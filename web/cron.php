<?php
//This file is a cron task which runs in the server every X minutes

include('db.php'); //initializes $conn = new mysqli();

$command1 = " SELECT id,user from farms WHERE `lastUpdated` < DATE_SUB(NOW(), INTERVAL 30 MINUTE) AND data<>'';";
$result1 = $conn -> query($command1);

//Deletes data older than 30 minutes
$command2 = " UPDATE farms SET `lastUpdated` = `lastUpdated`, data='' WHERE `lastUpdated` < DATE_SUB(NOW(), INTERVAL 30 MINUTE) ;";
$result2 = $conn -> query($command2);

//Notifies users if their rig has gone offline
while ($row = $result1 -> fetch_row())
{
    $id = $row[0];
    $user = $row[1];

    $command3 = " SELECT notify,name from offline WHERE id='" . $id . "'";
    $result3 = $conn -> query($command3);

    while ($row3 = $result3 -> fetch_row())
    {
      $notifyOffline = (int) $row3[0];
      $name = $row3[1];

      //sends notification if it is linked 
      if ($notifyOffline === 1 && $user !== "none" && gettype($user) == gettype("none"))
      {
        //send
        $arg = "offline";
        //send notification
        $commandNotif = " INSERT INTO notifications(user,type,name) VALUES ('" . $user . "', '" . $arg . "', '" . $name . "');";
        $conn -> query($commandNotif);

        //0 means it is not farming
        //1 means it is farming
         //2 means it is offline
        $isFarming = 2;
        $command5 = " UPDATE statuses set isfarming='" . $isFarming . "' WHERE id='" . $id . "';";
        $conn -> query($command5);
      }
    }
}

$conn -> close();

?>