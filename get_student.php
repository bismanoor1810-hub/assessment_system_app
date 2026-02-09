<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$conn = new mysqli("localhost", "savyanon_assessment_system", "193(h=3EkroW", "savyanon_assessment_system");

if ($conn->connect_error) {
    echo json_encode(["status" => false, "message" => "DB Connection Failed"]);
    exit;
}

$result = $conn->query("SELECT id, rollno, name, father_name FROM student_detail");

$students = [];

while ($row = $result->fetch_assoc()) {
    $students[] = $row;
}

echo json_encode([
    "status" => true,
    "data" => $students
]);
