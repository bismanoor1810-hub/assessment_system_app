<?php
header("Content-Type: application/json");
include "db.php";

$json = file_get_contents('php://input');
$data = json_decode($json, true);

if (!$data && isset($_POST['json_data'])) {
    $data = json_decode($_POST['json_data'], true);
}

if (!$data) {
    echo json_encode(["status" => false, "message" => "No data received."]);
    exit;
}

$student_id = $data['student_id'] ?? '';
$evaluated_by = $data['evaluated_by'] ?? '';
$evaluations = $data['evaluations'] ?? [];
$overall_comments = $data['overall_comments'] ?? '';

if (empty($student_id) || empty($evaluated_by) || empty($evaluations)) {
    echo json_encode(["status" => false, "message" => "Fields missing."]);
    exit;
}

$success_count = 0;
$errors = [];

foreach ($evaluations as $index => $eval) {
    $detail_id = $eval['assessment_detail_id'];
    $marks = $eval['obtained_marks'];
    
    // Overall comment sirf aakhri row mein ya har row mein save karein
    $comment = ($index === count($evaluations) - 1) ? $conn->real_escape_string($overall_comments) : "";

    // ✅ FIX: Hamesha INSERT karein taake history maintain ho aur data replace na ho
    $sql = "INSERT INTO student_evaluation (evaluated_student_id, evaluated_by, assessment_detail_id, obtained_marks, comments) 
            VALUES ('$student_id', '$evaluated_by', '$detail_id', '$marks', '$comment')";
    
    if ($conn->query($sql)) {
        $success_count++;
    } else {
        $errors[] = $conn->error;
    }
}

if ($success_count > 0) {
    echo json_encode(["status" => "true", "message" => "Saved $success_count records."]);
} else {
    echo json_encode(["status" => "false", "message" => "Error: " . implode(", ", $errors)]);
}
?>