<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

// Database connection include karein
include "db.php"; 

// POST data receive karein
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

// Basic validation
if (empty($email) || empty($password)) {
    echo json_encode([
        "status" => "false",
        "message" => "Email and Password are required"
    ]);
    exit;
}

// 1. Teacher ko database mein search karein
// Agar aap password encrypt (hash) use kar rahe hain to yahan logic change hogi
$sql = "SELECT id, name, email, role FROM teachers WHERE email = ? AND password = ? LIMIT 1";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $email, $password);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $teacher = $result->fetch_assoc();
    
    // Success Response: Flutter is "role" ko save karega
    echo json_encode([
        "status" => "true",
        "message" => "Teacher Login Successful",
        "user_id" => $teacher['id'],
        "name" => $teacher['name'],
        "role" => $teacher['role'] // 'teacher' value yahan se jayegi
    ]);
} else {
    // Failure Response
    echo json_encode([
        "status" => "false",
        "message" => "Invalid Teacher Credentials"
    ]);
}

$stmt->close();
$conn->close();
?>