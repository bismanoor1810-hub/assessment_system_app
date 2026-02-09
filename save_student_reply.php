<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db.php'; 

// Timezone set karein taake reply ka waqt sahi save ho agar aap column rakhte hain
date_default_timezone_set('Asia/Karachi');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Flutter se evaluation_id aur reply receive karna
    $evaluation_id = isset($_POST['evaluation_id']) ? mysqli_real_escape_string($conn, $_POST['evaluation_id']) : '';
    $reply = isset($_POST['reply']) ? mysqli_real_escape_string($conn, $_POST['reply']) : '';

    if (empty($evaluation_id) || empty($reply)) {
        echo json_encode(["status" => "false", "message" => "Missing ID or Reply"]);
        exit();
    }

    // Table 'student_evaluations' mein student_reply column ko update karna
    // Jahan id matches the primary key of the evaluation record
    $sql = "UPDATE student_evaluations SET student_reply = '$reply' WHERE id = '$evaluation_id'";

    if (mysqli_query($conn, $sql)) {
        echo json_encode([
            "status" => "true", 
            "message" => "Reply saved successfully on server"
        ]);
    } else {
        echo json_encode([
            "status" => "false", 
            "message" => "Database error: " . mysqli_error($conn)
        ]);
    }
} else {
    echo json_encode(["status" => "false", "message" => "Invalid Request"]);
}

mysqli_close($conn);
?>