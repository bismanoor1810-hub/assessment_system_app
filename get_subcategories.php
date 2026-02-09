<?php
header("Content-Type: application/json");
include "db.php";

$presentation_id = $_GET['presentation_id'];

if (!$presentation_id) {
    echo json_encode(["status" => "false", "message" => "Presentation ID missing"]);
    exit;
}

// Presentation ID ke mutabiq subcategories fetch karein
$sql = "SELECT id, presentation_id, title, type, max_marks 
        FROM presentation_subcategories 
        WHERE presentation_id = '$presentation_id'";

$result = $conn->query($sql);
$subcategories = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $subcategories[] = $row;
    }
    echo json_encode(["status" => "true", "data" => $subcategories]);
} else {
    echo json_encode(["status" => "false", "message" => "No criteria found", "data" => []]);
}
?>