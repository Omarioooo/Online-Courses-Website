-- sp_GetAllUsers
CREATE PROCEDURE sp_GetAllUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    -- Stop tracking of the num of affected rows
    SET NOCOUNT ON;

    -- Check if there are any users
    IF EXISTS (SELECT 1 FROM SystemUser WHERE [State] = 'AVAILABLE')
    BEGIN
        SELECT
            usr.UserID,
            usr.FirstName,
            usr.LastName,
            usr.Mail,
            r.RoleName
        FROM
            SystemUser usr
        INNER JOIN
            Role r ON usr.RoleID = r.RoleID
        WHERE
            usr.[State] = 'AVAILABLE';

        SET @ResultMessage = 'Done';
        RETURN;
    END
    ELSE
    BEGIN
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;
----------------------------------------------------------------------------------------
-- sp_GetUsersByRole
CREATE PROCEDURE sp_GetUsersByRole
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    -- Stop tracking of the number of affected rows
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM SystemUser usr
        INNER JOIN Role r ON usr.RoleID = r.RoleID
        WHERE usr.[State] = 'AVAILABLE'
          AND r.RoleID = @RoleID
    )
    BEGIN
        SELECT
            usr.UserID,
            usr.FirstName,
            usr.LastName,
            usr.Mail,
            r.RoleName
        FROM
            SystemUser usr
        INNER JOIN
            Role r ON usr.RoleID = r.RoleID
        WHERE
            usr.[State] = 'AVAILABLE'
          AND r.RoleID = @RoleID;

        SET @ResultMessage = 'Done';
        RETURN;
    END
    ELSE
    BEGIN
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;
-----------------------------------------------------------------------------------------
-- sp_GetUserByID
CREATE PROCEDURE sp_GetUserByID
    @UserID INT,
    @UserState VARCHAR(50) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    -- Stop tracking of the number of affected rows
    SET NOCOUNT ON;

    DECLARE @State VARCHAR(10);

    -- Check if the user exists
    IF EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID)
    BEGIN
        -- Get state of the user
        SELECT
            @State = [State]
        FROM
            SystemUser
        WHERE
            UserID = @UserID;

        -- Select user data
        SELECT
            usr.UserID,
            usr.FirstName,
            usr.LastName,
            usr.BirthDate,
            usr.Nationality,
            usr.Mail,
            usr.[Password],
            usr.Bio,
            usr.BankAccount,
            usr.ProfileName,
            usr.ProfilePhoto,
            usr.DateOfCreation,
            r.RoleName
        FROM
            SystemUser usr
        INNER JOIN
            Role r ON usr.RoleID = r.RoleID
        WHERE
            usr.UserID = @UserID;

        -- Return the state of the user
        IF (@State = 'AVAILABLE')
        BEGIN
            SET @UserState = 'User is available';
        END
        ELSE
        BEGIN
            SET @UserState = 'User is removed';
        END

        -- Always set ResultMessage here
        SET @ResultMessage = 'Done';
        RETURN;
    END
    ELSE
    BEGIN
        SET @UserState = NULL; -- nothing to return
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;
-----------------------------------------------------------------------------------------------
-- sp_DeleteUser
CREATE PROCEDURE sp_DeleteUser
    @UserID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    -- Stop tracking of the number of affected rows
    SET NOCOUNT ON;

    -- Check if the user exists
    IF EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID)
    BEGIN
        UPDATE SystemUser
		SET [State] = 'REMOVED'
		WHERE UserID = @UserID;

        -- Always set ResultMessage here
        SET @ResultMessage = 'Done';
        RETURN;
    END
    ELSE
    BEGIN
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;