<?php
header("Content-Type: application/json");
include "db.php";

$admin_id = $_GET['admin_id'];

if (!$admin_id) {
    echo json_encode(["status" => "false", "message" => "Admin ID missing"]);
    exit;
}

// Presentations fetch karein aur sath mein sub-categories ka count bhi le lein
$sql = "SELECT p.*, 
        (SELECT COUNT(*) FROM presentation_subcategories WHERE presentation_id = p.id) as criteria_count 
        FROM presentations p 
        WHERE p.created_by = '$admin_id' 
        ORDER BY p.id DESC";

$result = $conn->query($sql);
$presentations = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Status check karne ki logic (PHP side par)
        $current_now = date('Y-m-d H:i:s');
        $end_datetime = $row['end_date'] . ' ' . $row['end_time'];
        
        $row['is_active'] = (strtotime($end_datetime) > strtotime($current_now)) ? true : false;
        $presentations[] = $row;
    }
    echo json_encode(["status" => "true", "data" => $presentations]);
} else {
    echo json_encode(["status" => "false", "message" => "No presentations found"]);
}
?>