-- sp_GetAllUsers
CREATE PROCEDURE sp_GetAllUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    -- Stop tracking of the num of affected rows
    SET NOCOUNT ON;

    -- Get all available users with their roles
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

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No available users found.';
    ELSE
        SET @ResultMessage = 'Success';
END;
----------------------------------------------------------------------------------------
-- sp_GetUsersByRole
CREATE PROCEDURE sp_GetUsersByRole
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all available users by role
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

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No available users found for this role.';
    ELSE
        SET @ResultMessage = 'Success';
END;
-----------------------------------------------------------------------------------------
-- sp_GetUserByID
CREATE PROCEDURE sp_GetUserByID
    @UserID INT,
    @UserState VARCHAR(50) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get user info + role
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
        r.RoleName,
        usr.[State] AS InternalState
    FROM
        SystemUser usr
    INNER JOIN
        Role r ON usr.RoleID = r.RoleID
    WHERE
        usr.UserID = @UserID;

    -- Handle outputs
    IF @@ROWCOUNT = 0
    BEGIN
        SET @UserState = NULL;
        SET @ResultMessage = 'No user found with the given ID.';
    END
    ELSE
    BEGIN
        -- Derive user state meaning
        IF EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID AND [State] = 'AVAILABLE')
            SET @UserState = 'User is available';
        ELSE
            SET @UserState = 'User is removed';

        SET @ResultMessage = 'Success';
    END
END;
-----------------------------------------------------------------------------------------------
-- sp_DeleteUser
CREATE PROCEDURE sp_DeleteUser
    @UserID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Soft delete (mark as REMOVED)
    UPDATE SystemUser
    SET [State] = 'REMOVED'
    WHERE UserID = @UserID
      AND [State] <> 'REMOVED';

    -- Check result
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No user found.';
    ELSE
        SET @ResultMessage = 'Success';
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

    -- Try to get role directly
    SELECT
        @UserRole = r.RoleName
    FROM
        SystemUser usr
    INNER JOIN
        Role r ON r.RoleID = usr.RoleID
    WHERE
        usr.Mail = @Mail
        AND usr.[Password] = @Password
        AND usr.[State] = 'AVAILABLE';

    -- Check result
    IF @UserRole IS NULL
        SET @ResultMessage = 'Failed';
    ELSE
        SET @ResultMessage = 'Success';
END;
--------------------------------------------------------------------------------
-- sp_RegisterUser
CREATE PROCEDURE sp_RegisterUser
    @FirstName VARCHAR(25),
    @LastName VARCHAR(25),
    @BirthDate DATE,
    @Nationality VARCHAR(25),
    @Mail VARCHAR(100),
    @Password VARCHAR(100),
    @Bio TEXT = NULL,
    @BankAccount VARCHAR(20) = NULL,
    @ProfileName VARCHAR(50) = NULL,
    @ProfilePhoto VARCHAR(255) = NULL,
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM SystemUser WHERE Mail = @Mail)
    BEGIN
        SET @ResultMessage = 'Failed: Email already exists';
        RETURN;
    END

    -- Insert new user
    INSERT INTO SystemUser (
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
        GETDATE(),   -- Use current date as creation date
        @RoleID,
        'AVAILABLE'
    );

    SET @ResultMessage = 'Done';
END;