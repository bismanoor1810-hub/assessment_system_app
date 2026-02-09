<?php
error_reporting(0);
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Database connection
$conn = new mysqli("localhost", "savyanon_assessment_system", "193(h=3EkroW", "savyanon_assessment_system");

if ($conn->connect_error) {
    echo json_encode(["error" => "Database Connection failed"]);
    exit();
}

$student_id = isset($_GET['student_id']) ? $conn->real_escape_string($_GET['student_id']) : null;
$assessment_id = isset($_GET['assessment_id']) ? $conn->real_escape_string($_GET['assessment_id']) : null;

if (!$student_id || !$assessment_id) {
    echo json_encode(["error" => "Missing parameters"]);
    exit();
}

/**
 * JOIN Logic: 
 * test44 (presentation_evaluations) se student ka data uthayen ge
 * test55 (presentation_criteria) se criteria ka title (e.g. PPT, Confidence) uthayen ge
 */
$sql = "SELECT 
            pe.student_email, 
            pe.evaluator_email, 
            pe.presentation_id,
            pe.marks_obtained, 
            pe.comment_text,
            c.title AS criteria_name,  
            c.max_marks AS max_limit
        FROM student_evaluations pe
        INNER JOIN presentation_subcategories c ON pe.criteria_id = c.id
        WHERE pe.student_email = '$student_id' 
        AND pe.presentation_id = '$assessment_id'";

$result = $conn->query($sql);
$temp_records = array();

if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $evaluator = $row['evaluator_email'];
        
        // Grouping by evaluator to keep the local DB structure consistent
        if (!isset($temp_records[$evaluator])) {
            $temp_records[$evaluator] = [
                "evaluated_student_id" => $row['student_email'],
                "evaluated_by" => $evaluator,
                "assessment_id" => $row['presentation_id'],
                "evaluations" => []
            ];
        }
        
        $temp_records[$evaluator]["evaluations"][] = [
            "criteria_name" => $row['criteria_name'],
            "obtained_marks" => $row['marks_obtained'],
            "max_marks" => $row['max_limit'],
            "comments" => $row['comment_text']
        ];
    }
}

// Format the response for Flutter SQLite structure
$final_records = array();
foreach ($temp_records as $record) {
    $final_records[] = [
        "evaluated_student_id" => $record['evaluated_student_id'],
        "evaluated_by" => $record['evaluated_by'],
        "assessment_id" => $record['assessment_id'],
        "data" => json_encode(["evaluations" => $record['evaluations']])
    ];
}

echo json_encode($final_records);
$conn->close();
?>