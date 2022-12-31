<?php
header("Access-Control-Allow-Origin: *");
include('db.php'); //initializes $conn = new mysqli();

if ($conn -> connect_errno)
{
echo "Failed to connect to database!";
}

if ( isset($_GET['user']))
{
 $user = $conn -> real_escape_string($_GET['user']);

 $command = " SELECT id,data FROM farms WHERE user='" . $user . "' AND publicAPI=1 AND data<>'' AND data<>';;' ORDER BY lastUpdated DESC;";
 $result = $conn -> query($command);

 $data = array();

 $data['harvesters'] = array();

 while ($row = $result->fetch_row()) {
   $harvester = array();

   $harvester['id'] = $row[0];
   $harvester['data'] = json_decode($row[1]);

   array_push($data['harvesters'], $harvester);
 }

 echo json_encode($data);
}

$conn -> close();
?>
