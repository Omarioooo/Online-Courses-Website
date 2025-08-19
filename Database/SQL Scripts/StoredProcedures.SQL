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

    -- Check if the user exists and is not already removed
    IF EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID AND [State] <> 'REMOVED')
    BEGIN
        UPDATE SystemUser
        SET [State] = 'REMOVED'
        WHERE UserID = @UserID;

        SET @ResultMessage = 'Done';
        RETURN;
    END
    ELSE
    BEGIN
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;
-----------------------------------------------------------------------------------------------
-- sp_LoginUser
CREATE PROCEDURE sp_LoginUser
    @Mail VARCHAR(100),
    @Password VARCHAR(100),
    @UserRole VARCHAR(50) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if user exists with given mail & password
    IF EXISTS (
        SELECT 1
        FROM SystemUser
        WHERE Mail = @Mail
          AND [Password] = @Password
          AND [State] = 'AVAILABLE'
    )
    BEGIN
        -- Assign role name to output param
        SELECT @UserRole = r.RoleName
        FROM SystemUser usr
        INNER JOIN Role r ON r.RoleID = usr.RoleID
        WHERE usr.Mail = @Mail
          AND usr.[Password] = @Password
          AND usr.[State] = 'AVAILABLE';

        SET @ResultMessage = 'DONE';
        RETURN;
    END
    ELSE
    BEGIN
        SET @UserRole = NULL;
        SET @ResultMessage = 'Failed';
        RETURN;
    END
END;
--------------------------------------------------------------------------------
-- sp_RegisterUser
CREATE PROCEDURE sp_RegisterUser
    @UserID INT,
    @FirstName VARCHAR(25),
    @LastName VARCHAR(25),
    @BirthDate DATE,
    @Nationality VARCHAR(25),
    @Mail VARCHAR(100),
    @Password VARCHAR(100),
    @Bio TEXT,
    @BankAccount VARCHAR(20),
    @ProfileName VARCHAR(50),
    @ProfilePhoto VARCHAR(255),
    @DateOfCreation DATE,
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM SystemUser WHERE Mail = @Mail)
    BEGIN
        SET @ResultMessage = 'Failed';
        RETURN;
    END

    -- Insert new user
    INSERT INTO SystemUser (
        UserID,
        FirstName,
        LastName,
        BirthDate,
        Nationality,
        Mail,
        [Password],
        Bio,
        BankAccount,
        ProfileName,
        ProfilePhoto,
        DateOfCreation,
        RoleID,
        [State]
    )
    VALUES (
        @UserID,
        @FirstName,
        @LastName,
        @BirthDate,
        @Nationality,
        @Mail,
        @Password,
        @Bio,
        @BankAccount,
        @ProfileName,
        @ProfilePhoto,
        @DateOfCreation,
        @RoleID,
        'AVAILABLE' -- default state for new users
    );

    SET @ResultMessage = 'Done';
    RETURN;
END;
-------------------------------------------------------------------------------------
-- sp_GetTotalUsers
CREATE PROCEDURE sp_GetTotalUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users
	SELECT COUNT(UserID) TotalUsers
	FROM SystemUser

    SET @ResultMessage = 'Done';
END;