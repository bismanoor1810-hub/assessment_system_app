<?php
header("Content-Type: application/json");
include "db.php"; 

if (isset($_GET['category_id'])) {
    $cat_id = $conn->real_escape_string($_GET['category_id']);

    // Query: presentations fetch karein aur criteria ka count bhi lein
    $sql = "SELECT p.*, 
            (SELECT COUNT(*) FROM presentation_subcategories WHERE presentation_id = p.id) as criteria_count 
            FROM presentations p 
            WHERE p.category_id = '$cat_id' 
            ORDER BY p.id DESC";

    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $presentations = [];
        $current_now = date('Y-m-d H:i:s');

        while ($row = $result->fetch_assoc()) {
            // Status check: Agar end date/time guzar gaya to inactive
            $end_datetime = $row['end_date'] . ' ' . $row['end_time'];
            $row['is_active'] = (strtotime($end_datetime) > strtotime($current_now)) ? true : false;
            
            $presentations[] = $row;
        }
        echo json_encode(["status" => "true", "data" => $presentations]);
    } else {
        echo json_encode(["status" => "false", "message" => "No presentations found.", "data" => []]);
    }
} else {
    echo json_encode(["status" => "false", "message" => "category_id missing."]);
}
$conn->close();
?>