<?php
header("Content-Type: application/json");
include "db.php"; 

$json = file_get_contents('php://input');
$data = json_decode($json, true);

if (!$data) {
    echo json_encode(["status" => "false", "message" => "No data received."]);
    exit;
}

// ✅ Corrected: Pass category_id from Flutter
$category_id = $conn->real_escape_string($data['category_id']); 
$name = $conn->real_escape_string($data['name']);
$code = $conn->real_escape_string($data['code']);
$start_date = $conn->real_escape_string($data['start_date']);
$start_time = $conn->real_escape_string($data['start_time']); 
$end_date = $conn->real_escape_string($data['end_date']);
$end_time = $conn->real_escape_string($data['end_time']);      
$t_weight = (int)$data['teacher_weightage'];
$s_weight = (int)$data['student_weightage'];
$admin_id = $conn->real_escape_string($data['created_by']);
$sub_categories = $data['sub_categories']; 

// ✅ Corrected SQL: category_id must be inserted
$sql = "INSERT INTO presentations (category_id, name, code, start_date, start_time, end_date, end_time, teacher_weightage, student_weightage, created_by) 
        VALUES ('$category_id', '$name', '$code', '$start_date', '$start_time', '$end_date', '$end_time', '$t_weight', '$s_weight', '$admin_id')";

if ($conn->query($sql)) {
    $presentation_id = $conn->insert_id; 
    $success_sub = true;
    
    foreach ($sub_categories as $sub) {
        $type = $conn->real_escape_string($sub['type']);
        $title = $conn->real_escape_string($sub['title']);
        $max_marks = ($type == "Comments") ? 0 : (int)$sub['max_marks'];
        
        $sql_sub = "INSERT INTO presentation_subcategories (presentation_id, type, title, max_marks) 
                    VALUES ('$presentation_id', '$type', '$title', '$max_marks')";
        
        if (!$conn->query($sql_sub)) { $success_sub = false; }
    }

    if ($success_sub) {
        echo json_encode(["status" => "true", "message" => "Presentation Created!"]);
    } else {
        echo json_encode(["status" => "false", "message" => "Criteria failed to save."]);
    }
} else {
    echo json_encode(["status" => "false", "message" => "Error: " . $conn->error]);
}
?>