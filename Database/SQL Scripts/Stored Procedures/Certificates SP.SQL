-- sp_GenerateCertificate
CREATE PROCEDURE sp_GenerateCertificate
    @EnrollmentID INT,
    @CertificatePhoto VARCHAR(255),  -- path to generated certificate
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if enrollment exists
        IF NOT EXISTS (SELECT 1 FROM Enrollment WHERE EnrollmentID = @EnrollmentID)
        BEGIN
            SET @ResultMessage = 'Enrollment not found.';
            RETURN;
        END

        -- Check if certificate already exists
        IF EXISTS (SELECT 1 FROM Enrollment WHERE EnrollmentID = @EnrollmentID AND CertificateID IS NOT NULL)
        BEGIN
            SET @ResultMessage = 'Certificate already issued.';
            RETURN;
        END

        DECLARE @StudentID INT, @CourseID INT;
        SELECT @StudentID = StudentID, @CourseID = CourseID FROM Enrollment WHERE EnrollmentID = @EnrollmentID;

        -- Check lessons completion
        DECLARE @TotalLessons INT, @CompletedLessons INT;

        SELECT @TotalLessons = COUNT(*)
        FROM Lesson l
        JOIN Section s ON l.SectionID = s.SectionID
        WHERE s.CourseID = @CourseID;

        SELECT @CompletedLessons = COUNT(*)
        FROM StudentLessonProgress slp
        JOIN Lesson l ON slp.LessonID = l.LessonID
        JOIN Section s ON l.SectionID = s.SectionID
        WHERE slp.StudentID = @StudentID
          AND s.CourseID = @CourseID
          AND slp.IsCompleted = 1;

        -- Check quizzes completion
        DECLARE @TotalQuizzes INT, @PassedQuizzes INT;

        SELECT @TotalQuizzes = COUNT(*)
        FROM Quiz q
        JOIN Section s ON q.SectionID = s.SectionID
        WHERE s.CourseID = @CourseID;

        SELECT @PassedQuizzes = COUNT(*)
        FROM StudentQuizProgress sqp
        JOIN Quiz q ON sqp.QuizID = q.QuizID
        JOIN Section s ON q.SectionID = s.SectionID
        WHERE sqp.StudentID = @StudentID
          AND s.CourseID = @CourseID
          AND sqp.IsPassed = 1;

        -- Check if all lessons and quizzes are completed
        IF @TotalLessons = 0 OR @CompletedLessons < @TotalLessons
            OR @TotalQuizzes = 0 OR @PassedQuizzes < @TotalQuizzes
        BEGIN
            SET @ResultMessage = 'Course not fully completed. Certificate cannot be generated.';
            RETURN;
        END

        -- Insert new certificate
        DECLARE @CertID INT;
        INSERT INTO Certificate (GivenDate, CertificatePhoto)
        VALUES (GETDATE(), @CertificatePhoto);

        SET @CertID = SCOPE_IDENTITY();

        -- Update enrollment with certificate
        UPDATE Enrollment
        SET CertificateID = @CertID
        WHERE EnrollmentID = @EnrollmentID;

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
--------------------------------------------------------------------------------------------
-- sp_GetCertificatesByStudent
CREATE PROCEDURE sp_GetCertificatesByStudent
    @StudentID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.EnrollmentID,
        c.CertificateID,
        c.GivenDate,
        c.CertificatePhoto,
        co.Title AS CourseTitle,
        co.Description AS CourseDescription
    FROM Enrollment e
    JOIN Certificate c ON e.CertificateID = c.CertificateID
    JOIN Course co ON e.CourseID = co.CourseID
    WHERE e.StudentID = @StudentID
    ORDER BY c.GivenDate DESC;

    SET @ResultMessage = 'Success';
END;

