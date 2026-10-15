# HealthSync - Consistency Report

## Phân tích sự bất nhất giữa nghiệp vụ và cơ sở dữ liệu

**1. Thiếu mô hình trạng thái lịch hẹn.** Bảng `Appointments` cũ sử dụng `is_active BOOLEAN`, chỉ biểu diễn hai trạng thái bật và tắt. Trong khi đó, quy trình HealthSync yêu cầu năm trạng thái: `PENDING`, `CONFIRMED`, `CHECKED_IN`, `COMPLETED` và `CANCELLED`. Thiết kế mới thay Boolean bằng `status ENUM` để biểu diễn rõ vòng đời lịch hẹn.

**2. Thiếu dữ liệu tài chính và thông tin hủy lịch.** Thiết kế cũ không có `deposit_amount`, `penalty_fee` và `cancel_reason`. Khi bệnh nhân hủy sau khi xác nhận, hệ thống không thể ghi nhận số tiền cọc, khoản phạt và lý do hủy. Thiết kế mới sử dụng `DECIMAL(12,2)` cho tiền nhằm tránh sai số số học của `FLOAT` và `DOUBLE`, đồng thời bổ sung trường lý do hủy.

**3. Thiếu bảng đơn thuốc và kiểm soát nghiệp vụ.** Cơ sở dữ liệu cũ không có bảng `Prescriptions`, khiến đơn thuốc không thể liên kết với lịch khám. Thiết kế mới tạo bảng này với khóa chính, khóa ngoại và ràng buộc `UNIQUE(appointment_id)` để mỗi lịch hẹn có tối đa một đơn thuốc. Trigger ngăn tạo đơn thuốc khi lịch chưa ở trạng thái `COMPLETED`.

## Kết luận

ERD phải phản ánh đầy đủ dữ liệu và trạng thái trong Activity Diagram. Các kiểu dữ liệu, khóa và ràng buộc mới giúp hệ thống lưu trữ nhất quán hơn. Tuy nhiên, ứng dụng vẫn cần kiểm tra các chuyển đổi trạng thái hợp lệ và quản lý cập nhật dữ liệu trong transaction để tránh sai lệch nghiệp vụ.