CREATE DATABASE IF NOT EXISTS healthsync_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE healthsync_db;

-- Xoa trigger va bang phu thuoc neu da ton tai
DROP TRIGGER IF EXISTS trg_prescription_requires_completed;
DROP TABLE IF EXISTS Prescriptions;
DROP TABLE IF EXISTS Appointments;

CREATE TABLE IF NOT EXISTS Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50)
) ENGINE = InnoDB;

CREATE TABLE Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status ENUM(
        'PENDING',
        'CONFIRMED',
        'CHECKED_IN',
        'COMPLETED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'PENDING',
    deposit_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    penalty_fee DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    cancel_reason VARCHAR(255) NULL,

    CONSTRAINT FK_Appointments_Patients
        FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT FK_Appointments_Doctors
        FOREIGN KEY (doctor_id)
        REFERENCES Doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT CK_Deposit_NonNegative
        CHECK (deposit_amount >= 0),

    CONSTRAINT CK_Penalty_NonNegative
        CHECK (penalty_fee >= 0),

    CONSTRAINT CK_Penalty_NotExceedDeposit
        CHECK (penalty_fee <= deposit_amount),

    CONSTRAINT CK_CancelReason
        CHECK (
            status <> 'CANCELLED'
            OR cancel_reason IS NOT NULL
        )
) ENGINE = InnoDB;

CREATE TABLE Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    medication_details TEXT NOT NULL,
    issued_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_Prescriptions_Appointments
        FOREIGN KEY (appointment_id)
        REFERENCES Appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

DELIMITER $$

CREATE TRIGGER trg_prescription_requires_completed
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SET v_status = (
        SELECT status
        FROM Appointments
        WHERE appointment_id = NEW.appointment_id
    );

    IF v_status IS NULL OR v_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Prescription requires a COMPLETED appointment';
    END IF;
END$$

DELIMITER ;

-- Them du lieu mau
INSERT INTO Patients (full_name, phone)
VALUES
    ('Nguyen Van An', '0900000001'),
    ('Tran Thi Binh', '0900000002');

INSERT INTO Doctors (full_name, specialty)
VALUES ('Le Minh Chau', 'Noi khoa');

SET @patient1 = (
    SELECT patient_id FROM Patients
    WHERE phone = '0900000001'
    LIMIT 1
);

SET @patient2 = (
    SELECT patient_id FROM Patients
    WHERE phone = '0900000002'
    LIMIT 1
);

SET @doctor1 = (
    SELECT doctor_id FROM Doctors
    WHERE full_name = 'Le Minh Chau'
    LIMIT 1
);

-- Kich ban 1: kham thanh cong
INSERT INTO Appointments (
    patient_id, doctor_id, appointment_date,
    status, deposit_amount, penalty_fee
)
VALUES (
    @patient1, @doctor1, '2026-10-20 09:00:00',
    'PENDING', 500000.00, 0.00
);

SET @appointment1 = LAST_INSERT_ID();

UPDATE Appointments
SET status = 'CONFIRMED'
WHERE appointment_id = @appointment1
  AND status = 'PENDING';

UPDATE Appointments
SET status = 'CHECKED_IN'
WHERE appointment_id = @appointment1
  AND status = 'CONFIRMED';

UPDATE Appointments
SET status = 'COMPLETED'
WHERE appointment_id = @appointment1
  AND status = 'CHECKED_IN';

INSERT INTO Prescriptions (appointment_id, medication_details)
VALUES (
    @appointment1,
    'Paracetamol 500mg - use as directed by doctor.'
);

-- Kich ban 2: huy lich da xac nhan
INSERT INTO Appointments (
    patient_id, doctor_id, appointment_date,
    status, deposit_amount, penalty_fee
)
VALUES (
    @patient2, @doctor1, '2026-10-21 14:00:00',
    'CONFIRMED', 300000.00, 0.00
);

SET @appointment2 = LAST_INSERT_ID();

UPDATE Appointments
SET status = 'CANCELLED',
    cancel_reason = 'Ban viec dot xuat',
    penalty_fee = 150000.00
WHERE appointment_id = @appointment2
  AND status = 'CONFIRMED';

-- Kiem tra tien coc va phi phat
SELECT
    appointment_id,
    status,
    deposit_amount,
    penalty_fee,
    deposit_amount - penalty_fee AS deposit_remaining,
    cancel_reason
FROM Appointments
ORDER BY appointment_id;

-- Kiem tra don thuoc
SELECT
    a.appointment_id,
    p.full_name AS patient_name,
    d.full_name AS doctor_name,
    a.appointment_date,
    a.status,
    a.deposit_amount,
    pr.prescription_id,
    pr.medication_details,
    pr.issued_date
FROM Appointments AS a
JOIN Patients AS p ON a.patient_id = p.patient_id
JOIN Doctors AS d ON a.doctor_id = d.doctor_id
LEFT JOIN Prescriptions AS pr
    ON a.appointment_id = pr.appointment_id
WHERE a.status = 'COMPLETED';

-- Kiem tra lich da huy
SELECT
    appointment_id,
    status,
    deposit_amount,
    penalty_fee,
    deposit_amount - penalty_fee AS deposit_remaining,
    cancel_reason
FROM Appointments
WHERE status = 'CANCELLED';