<?php
header("Content-Type: application/json");
include 'db.php';

$student_id = $_GET['student_id'];
$cat_id = $_GET['category_id']; // Ye ID ya toh Category hogi ya Presentation

$response = ["status" => "false", "data" => [], "overall_average" => 0];

// Step 1: Pehle check karein ke di gayi ID Presentation hai ya Category
// Hum dono cases ko cover karenge
$filter = "(p.category_id = '$cat_id' OR p.id = '$cat_id')";

// Step 2: Overall Calculation (Strictly ignore 0 max marks)
$avg_sql = "SELECT SUM(e.marks_obtained) as total_get, SUM(s.max_marks) as total_max 
            FROM student_evaluations e
            JOIN presentation_subcategories s ON e.criteria_id = s.id
            JOIN presentations p ON e.presentation_id = p.id
            WHERE e.student_email = '$student_id' 
            AND $filter AND s.max_marks > 0";

$avg_res = mysqli_query($conn, $avg_sql);
$avg_row = mysqli_fetch_assoc($avg_res);
$overall_avg = ($avg_row['total_max'] > 0) ? ($avg_row['total_get'] / $avg_row['total_max']) * 100 : 0;

// Step 3: Detailed Data (Criteria wise dikhana behtar hai)
$sql = "SELECT s.title, e.marks_obtained, s.max_marks, e.evaluator_email
        FROM student_evaluations e
        JOIN presentation_subcategories s ON e.criteria_id = s.id
        JOIN presentations p ON e.presentation_id = p.id
        WHERE e.student_email = '$student_id' AND $filter
        ORDER BY p.id ASC";

$result = mysqli_query($conn, $sql);
$logs = [];

while($row = mysqli_fetch_assoc($result)) {
    $logs[] = [
        "criteria" => $row['title'],
        "evaluator" => explode('@', $row['evaluator_email'])[0],
        "score" => $row['marks_obtained'] . "/" . $row['max_marks'],
        "percentage" => ($row['max_marks'] > 0) ? round(($row['marks_obtained'] / $row['max_marks']) * 100, 1) : " "
    ];
}

echo json_encode([
    "status" => "true",
    "overall_average" => round($overall_avg, 1),
    "data" => $logs
]);
?>
