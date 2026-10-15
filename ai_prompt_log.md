# HealthSync - AI Prompt Log

## 1. Phân tích trạng thái lịch hẹn

**Câu hỏi:** Tại sao dùng `is_active BOOLEAN` để theo dõi vòng đời lịch hẹn là thiết kế chưa phù hợp?

**Tóm tắt:** Boolean chỉ biểu diễn hai giá trị, không đủ để mô tả năm trạng thái nghiệp vụ của lịch hẹn.

**Quyết định thiết kế:** Thay bằng `status ENUM` gồm `PENDING`, `CONFIRMED`, `CHECKED_IN`, `COMPLETED` và `CANCELLED`.

## 2. Lựa chọn kiểu dữ liệu tài chính

**Câu hỏi:** Nên dùng `FLOAT`, `DOUBLE` hay `DECIMAL` để lưu tiền cọc và phí phạt trong MySQL?

**Tóm tắt:** `FLOAT` và `DOUBLE` có thể phát sinh sai số biểu diễn số thực. `DECIMAL` phù hợp hơn với giá trị tiền tệ cần độ chính xác thập phân.

**Quyết định thiết kế:** Sử dụng `DECIMAL(12,2)` cho `deposit_amount` và `penalty_fee`, đồng thời đặt giá trị mặc định bằng 0 và ràng buộc không âm.

## 3. Thiết kế quan hệ đơn thuốc

**Câu hỏi:** Làm thế nào liên kết bảng `Prescriptions` với `Appointments` và giới hạn mỗi lịch hẹn có tối đa một đơn thuốc?

**Tóm tắt:** Khóa ngoại bảo đảm đơn thuốc tham chiếu đến lịch hẹn tồn tại. Ràng buộc `UNIQUE` trên `appointment_id` giới hạn mỗi lịch hẹn có tối đa một đơn thuốc.

**Quyết định thiết kế:** Chọn quan hệ 1–1 cho phạm vi bài thực hành. Nếu nghiệp vụ cho phép nhiều đơn thuốc cho một lần khám, có thể chuyển sang quan hệ 1–N.

## 4. Kiểm soát việc kê đơn

**Câu hỏi:** Khóa ngoại có ngăn được việc tạo đơn thuốc khi lịch hẹn chưa hoàn tất không?

**Tóm tắt:** Không. Khóa ngoại chỉ kiểm tra tính tồn tại của bản ghi được tham chiếu, không kiểm tra trạng thái nghiệp vụ của lịch hẹn.

**Quyết định thiết kế:** Sử dụng trigger `BEFORE INSERT` trên bảng `Prescriptions`. Trigger kiểm tra trạng thái lịch hẹn và từ chối thao tác nếu trạng thái chưa phải `COMPLETED`.

## 5. Lựa chọn hành vi khóa ngoại

**Câu hỏi:** Khi thiết kế dữ liệu lịch khám và đơn thuốc, nên chọn `ON DELETE CASCADE` hay `ON DELETE RESTRICT`?

**Tóm tắt:** `CASCADE` có thể xóa dữ liệu liên quan tự động, nhưng có nguy cơ làm mất lịch sử y tế. `RESTRICT` ngăn xóa bản ghi cha khi vẫn còn dữ liệu tham chiếu.

**Quyết định thiết kế:** Chọn `ON DELETE RESTRICT` để hạn chế xóa nhầm lịch khám và đơn thuốc.

## 6. Đánh giá kết quả

**Câu hỏi:** Cần kiểm tra những gì để xác nhận cơ sở dữ liệu phù hợp với quy trình HealthSync?

**Tóm tắt:** Kiểm tra vòng đời lịch hẹn, giá trị tiền cọc và phí phạt, lý do hủy, quan hệ giữa lịch hẹn và đơn thuốc, đồng thời kiểm thử trigger.

**Quyết định thiết kế:** Thực hiện hai kịch bản: khám hoàn tất và hủy lịch có phí phạt. Dùng các truy vấn `SELECT` và `JOIN` để đối chiếu kết quả.

## Kết luận

AI được sử dụng để hỗ trợ phân tích lỗ hổng dữ liệu, tìm hiểu cú pháp MySQL và phản biện các lựa chọn thiết kế. Người thực hiện cần tự chạy script, xác minh kết quả và điều chỉnh theo phiên bản MySQL đang sử dụng.
