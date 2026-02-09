<?php
include "db.php";

$category_id = $_GET['category_id'] ?? '';

if ($category_id == '') {
    echo json_encode([
        "status" => false,
        "message" => "Category ID required"
    ]);
    exit;
}

$sql = "SELECT * FROM assessment_details 
        WHERE assessment_category_id = '$category_id'";
$result = $conn->query($sql);

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode([
    "status" => true,
    "data" => $data
]);
?>