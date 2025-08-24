-- sp_CreateQuiz
CREATE PROCEDURE sp_CreateQuiz
    @Title VARCHAR(100),
    @SectionID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Quiz WHERE SectionID = @SectionID)
    BEGIN
        SET @ResultMessage = 'A quiz already exists for this section.';
        RETURN;
    END

    INSERT INTO Quiz (Title, SectionID)
    VALUES (@Title, @SectionID);

    SET @ResultMessage = 'Success';
END;
----------------------------------------------------------------------------
-- sp_GetQuizBySection
CREATE PROCEDURE sp_GetQuizBySection
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;

     IF NOT EXISTS (SELECT 1 FROM Quiz WHERE SectionID = @SectionID)
         BEGIN
             SET @ResultMessage = 'A quiz already not exists for this section.';
             RETURN;
         END

    SELECT QuizID, Title
    FROM Quiz
    WHERE SectionID = @SectionID;

    SET @ResultMessage = 'Success';
END;
-----------------------------------------------------------------------
-- sp_CreateQuestion
CREATE PROCEDURE sp_CreateQuestion
    @QuesContent TEXT,
    @ChooseA VARCHAR(255),
    @ChooseB VARCHAR(255),
    @ChooseC VARCHAR(255),
    @ChooseD VARCHAR(255),
    @CorrectChoice CHAR(1),
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Question (QuizID, QuesContent, ChooseA, ChooseB, ChooseC, ChooseD, CorrectChoice)
    VALUES (@QuesContent, @ChooseA, @ChooseB, @ChooseC, @ChooseD, @CorrectChoice);

    SET @ResultMessage = 'Success';
END;
-------------------------------------------------------------------------
-- sp_DeleteQuestion
CREATE PROCEDURE sp_DeleteQuestion
    @QuesID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if question exists
        IF NOT EXISTS (SELECT 1 FROM Question WHERE QuesID = @QuesID)
        BEGIN
            SET @ResultMessage = 'Question not found.';
            RETURN;
        END

        -- Delete any student answers associated with this question
        DELETE FROM StudentAnswer
        WHERE QuesID = @QuesID;

        -- Delete the question itself
        DELETE FROM Question
        WHERE QuesID = @QuesID;

        COMMIT TRANSACTION;
        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Failed to delete question: ' + ERROR_MESSAGE();
    END CATCH
END;
-------------------------------------------------------------------------
-- sp_GetQuestionsByQuiz
CREATE PROCEDURE sp_GetQuestionsByQuiz
    @QuizID INT
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Quiz WHERE QuizID = @QuizID)
        BEGIN
            SET @ResultMessage = 'A quiz not exists';
            RETURN;
        END

    SELECT
        QuesID,
        QuesContent,
        ChooseA,
        ChooseB,
        ChooseC,
        ChooseD,
        CorrectChoice
    FROM
        Question
    WHERE
        QuizID = @QuizID;

    SET @ResultMessage = 'Success';
END;
--------------------------------------------------------------------
-- sp_SubmitAnswer
CREATE PROCEDURE sp_SubmitAnswer
    @StudentID INT,
    @QuesID INT,
    @Choose CHAR(1),
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM StudentAnswer WHERE StudentID = @StudentID AND QuesID = @QuesID)
    BEGIN
        UPDATE StudentAnswer
        SET [Choose] = @Choose
        WHERE StudentID = @StudentID AND QuesID = @QuesID;

        SET @ResultMessage = 'Answer updated successfully.';
    END
    ELSE
    BEGIN
        INSERT INTO StudentAnswer (StudentID, QuesID, [Choose])
        VALUES (@StudentID, @QuesID, @Choose);

        SET @ResultMessage = 'Success';
    END
END;
--------------------------------------------------------------------------------
-- sp_GradeQuiz
CREATE PROCEDURE sp_GradeQuiz
    @StudentID INT,
    @QuizID INT,
    @Score DECIMAL(5,2) OUTPUT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalQuestions INT, @CorrectAnswers INT;

    -- Count total questions in the quiz
    SELECT @TotalQuestions = COUNT(*)
    FROM Question
    WHERE QuizID = @QuizID;

    -- Count correct answers by the student
    SELECT @CorrectAnswers = COUNT(*)
    FROM Question q
    JOIN StudentAnswer sa
        ON q.QuesID = sa.QuesID
    WHERE q.QuizID = @QuizID
      AND sa.StudentID = @StudentID
      AND q.CorrectChoice = sa.[Choose];

    -- Calculate score percentage
    IF @TotalQuestions > 0
    BEGIN
        SET @Score = CAST(@CorrectAnswers * 100.0 / @TotalQuestions AS DECIMAL(5,2));
        SET @ResultMessage = 'Success';
    END
    ELSE
    BEGIN
        SET @Score = 0;
        SET @ResultMessage = 'No questions found in this quiz.';
    END
END;
---------------------------------------------------------------------------
-- sp_GetAnswersByStudentAndQuiz
CREATE PROCEDURE sp_GetAnswersByStudentAndQuiz
    @StudentID INT,
    @QuizID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Question WHERE QuizID = @QuizID)
    BEGIN
        SET @ResultMessage = 'No questions found for this quiz.';
        RETURN;
    END

    SET @ResultMessage = 'Success';

    SELECT
        q.QuesID,
        q.QuesContent,
        q.ChooseA,
        q.ChooseB,
        q.ChooseC,
        q.ChooseD,
        q.CorrectChoice,
        sa.[Choose] AS StudentChoice,
        CASE WHEN sa.[Choose] = q.CorrectChoice THEN 1 ELSE 0 END AS IsCorrect
    FROM Question q
    LEFT JOIN StudentAnswer sa
        ON q.QuesID = sa.QuesID AND sa.StudentID = @StudentID
    WHERE q.QuizID = @QuizID;
END;