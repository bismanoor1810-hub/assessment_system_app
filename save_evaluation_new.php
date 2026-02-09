<?php
header("Content-Type: application/json");
include "db.php";

// Flutter se aane wala JSON data read karein
$json = file_get_contents('php://input');
$data = json_decode($json, true);

if ($data) {
    $student = $data['evaluated_student_id'];
    $evaluator = $data['evaluated_by'];
    $p_id = $data['presentation_id'];
    $evaluations = $data['evaluations']; // Ye list hai criteria ki

    $successCount = 0;

    foreach ($evaluations as $row) {
        $c_id = $row['assessment_detail_id'];
        $marks = $row['obtained_marks'];
        $comment = $conn->real_escape_string($row['comments']);

        $sql = "INSERT INTO student_evaluations (student_email, evaluator_email, presentation_id, criteria_id, marks_obtained, comment_text) 
                VALUES ('$student', '$evaluator', '$p_id', '$c_id', '$marks', '$comment')";
        
        if ($conn->query($sql)) {
            $successCount++;
        }
    }

    echo json_encode(["status" => "true", "message" => "Successfully saved $successCount records"]);
} else {
    echo json_encode(["status" => "false", "message" => "No data received"]);
}
?>