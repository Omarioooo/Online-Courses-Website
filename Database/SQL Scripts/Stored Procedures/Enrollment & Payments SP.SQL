CREATE PROCEDURE sp_EnrollStudentInCourse
    @StudentID INT,
    @CourseID INT,
    @PaymentMethod VARCHAR(50) = NULL,
    @ResultMessage VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CoursePrice DECIMAL(10,2);
    DECLARE @EnrollmentID INT;
    DECLARE @InstructorID INT;
    DECLARE @PaymentID INT;
    DECLARE @PlatformCut DECIMAL(10,2);
    DECLARE @InstructorShare DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if course exists and is approved
        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND [State] = 'Approved')
        BEGIN
            SET @ResultMessage = 'Course not available or not approved.';
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Prevent duplicate enrollment
        IF EXISTS (SELECT 1 FROM Enrollment WHERE StudentID = @StudentID AND CourseID = @CourseID)
        BEGIN
            SET @ResultMessage = 'Student already enrolled in this course.';
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Get course price and instructor
        SELECT
            @CoursePrice = c.Price,
            @InstructorID = cc.InstructorID
        FROM 
		    Course c
		JOIN 
		    CourseCreation cc ON cc.CreationID = c.CreationID
        WHERE
		    CourseID = @CourseID;
		 

        -- Insert Enrollment
        INSERT INTO Enrollment (EnrollmentDate, StudentID, CourseID)
        VALUES (GETDATE(), @StudentID, @CourseID);

        SET @EnrollmentID = SCOPE_IDENTITY();

        -- Handle Payment if course is paid
        IF @CoursePrice > 0
        BEGIN
            IF @PaymentMethod IS NULL
            BEGIN
                SET @ResultMessage = 'Payment method required for paid courses.';
                ROLLBACK TRANSACTION;
                RETURN;
            END;

            -- Split Payment
            SET @PlatformCut = @CoursePrice * 0.20;
            SET @InstructorShare = @CoursePrice * 0.80;

            -- Insert Payment
            INSERT INTO Payment (EnrollmentID, Amount, PlatformCut, InstructorShare, PaymentMethod, Status)
            VALUES (@EnrollmentID, @CoursePrice, @PlatformCut, @InstructorShare, @PaymentMethod, 'Completed');

            SET @PaymentID = SCOPE_IDENTITY();

            -- Ensure Instructor Wallet exists
            IF NOT EXISTS (SELECT 1 FROM VirtualInstructorWallet WHERE UserID = @InstructorID)
            BEGIN
                INSERT INTO VirtualInstructorWallet (UserID, Balance)
                VALUES (@InstructorID, 0);
            END;

            -- Update Instructor Wallet
            UPDATE VirtualInstructorWallet
            SET Balance = Balance + @InstructorShare,
                LastUpdated = GETDATE()
            WHERE UserID = @InstructorID;

            -- Update Platform Wallet
            UPDATE VirtualPlatformWallet
            SET Balance = Balance + @PlatformCut,
                LastUpdated = GETDATE()
            WHERE WalletName = 'MainPlatformWallet';

            -- Insert Wallet Transactions (Instructor Credit)
            INSERT INTO WalletTransaction (UserID, Amount, TransactionType, TransactionSource, Description, RelatedPaymentID, RelatedEnrollmentID)
            VALUES (@InstructorID, @InstructorShare, 'CREDIT', 'CourseEnrollment', 'Instructor share credited', @PaymentID, @EnrollmentID);

            -- Insert Wallet Transactions (Platform Credit)
            INSERT INTO WalletTransaction (UserID, Amount, TransactionType, TransactionSource, Description, RelatedPaymentID, RelatedEnrollmentID)
            VALUES (NULL, @PlatformCut, 'CREDIT', 'CourseEnrollment', 'Platform revenue credited', @PaymentID, @EnrollmentID);

            SET @ResultMessage = 'Success';
        END
        ELSE
        BEGIN
            SET @ResultMessage = 'Success';
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
------------------------------------------------------------------------------------
-- sp_GetInstructorRevenue
CREATE PROCEDURE sp_GetInstructorRevenue
    @InstructorID INT,
    @TotalRevenue DECIMAL(12,2) OUTPUT,
    @ResultMessage VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check instructor exists
        IF NOT EXISTS (
            SELECT 1
            FROM SystemUser
            WHERE UserID = @InstructorID
              AND RoleID IN (SELECT RoleID FROM Role WHERE RoleName = 'Instructor')
        )
        BEGIN
            SET @ResultMessage = 'Invalid InstructorID.';
            SET @TotalRevenue = 0;
            RETURN;
        END;

        -- Calculate all money instructor gained
        SELECT @TotalRevenue = ISNULL(SUM(p.InstructorShare), 0)
        FROM Payment p
        JOIN Enrollment e ON p.EnrollmentID = e.EnrollmentID
        JOIN Course c ON e.CourseID = c.CourseID
		JOIN CourseCreation cc ON cc.CreationID = c.CreationID
        WHERE cc.InstructorID = @InstructorID
          AND p.Status = 'Completed';

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @TotalRevenue = 0;
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
