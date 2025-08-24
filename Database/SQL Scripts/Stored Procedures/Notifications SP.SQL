-- sp_CreateNotification
CREATE PROCEDURE sp_CreateNotification
    @UserID INT,
    @TypeID INT,
    @Message NVARCHAR(255),
    @RelatedCourseID INT = NULL,
    @RelatedEnrollmentID INT = NULL,
    @ResultMessage NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO Notification (
            UserID,
            TypeID,
            Message,
            RelatedCourseID,
            RelatedEnrollmentID,
            CreatedAt,
            IsRead
        )
        VALUES (
            @UserID,
            @TypeID,
            @Message,
            @RelatedCourseID,
            @RelatedEnrollmentID,
            GETDATE(),
            0
        );

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
----------------------------------------------------------------------------------------
-- sp_MarkNotificationAsRead
CREATE PROCEDURE sp_MarkNotificationAsRead
    @NotificationID INT,
    @ResultMessage NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE Notification
        SET IsRead = 1
        WHERE NotificationID = @NotificationID;

        IF @@ROWCOUNT = 0
            SET @ResultMessage = 'Notification not found.';
        ELSE
            SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
-------------------------------------------------------------------------------------------
-- sp_GetNotificationsByUser
CREATE PROCEDURE sp_GetNotificationsByUser
    @UserID INT,
    @ResultMessage NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.NotificationID,
        nt.TypeName,
        n.Message,
        n.IsRead,
        n.CreatedAt,
        n.RelatedCourseID,
        n.RelatedEnrollmentID
    FROM Notification n
    JOIN NotificationType nt ON n.TypeID = nt.TypeID
    WHERE n.UserID = @UserID
    ORDER BY n.CreatedAt DESC;

    SET @ResultMessage = 'Success';
END;