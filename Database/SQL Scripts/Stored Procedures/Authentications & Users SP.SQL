-- Get all users in the system
-- Use LINQ to fillter the state of the user
-- Use LINQ to know the Number of users (Admin, Instructor, Studnet) in the system

CREATE PROCEDURE sp_GetAllUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all available users with their roles
    SELECT
        usr.UserID,
        usr.FirstName,
        usr.LastName,
        usr.Mail,
        r.RoleName,
        usr.[State]
    FROM SystemUser usr
    INNER JOIN Role r ON usr.RoleID = r.RoleID;

    -- Success / No Data message
    IF NOT EXISTS (SELECT 1 FROM SystemUser)
        SET @ResultMessage = 'No available users found.';
    ELSE
        SET @ResultMessage = 'Success';
END;
----------------------------------------------------------------------------------------
-- Get all Data of the specifec user in the system
-- May Use for displaying portofolios

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
        usr.[State]
    FROM SystemUser usr
    INNER JOIN Role r ON usr.RoleID = r.RoleID
    WHERE usr.UserID = @UserID;

    -- Handle outputs
    IF NOT EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID)
    BEGIN
        SET @UserState = NULL;
        SET @ResultMessage = 'No user found with the given ID.';
    END
    ELSE
    BEGIN
        SELECT @UserState =
            CASE WHEN [State] = 'AVAILABLE' THEN 'User is available'
                 ELSE 'User is removed'
            END
        FROM SystemUser WHERE UserID = @UserID;

        SET @ResultMessage = 'Success';
    END
END;
-----------------------------------------------------------------------------------------------
-- Delete a user from the system it's for Admins roles
-- Soft delete just change the state to Removed

-- sp_DeleteUser
CREATE PROCEDURE sp_DeleteUser
    @UserID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if user exists and not already removed
    IF NOT EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID AND [State] <> 'REMOVED')
    BEGIN
        SET @ResultMessage = 'No active user found with this ID.';
        RETURN;
    END;

    -- Soft delete (mark as REMOVED)
    UPDATE SystemUser
    SET [State] = 'REMOVED'
    WHERE UserID = @UserID;

    SET @ResultMessage = 'Success';
END;
-----------------------------------------------------------------------------------------------
-- sp_UpdateUser
CREATE PROCEDURE sp_UpdateUser
    @UserID INT,
    @Password VARCHAR(100) = NULL,
    @Bio TEXT = NULL,
    @BankAccount VARCHAR(20) = NULL,
    @ProfileName VARCHAR(50) = NULL,
    @ProfilePhoto VARCHAR(255) = NULL,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if user exists and is AVAILABLE
    IF NOT EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @UserID AND [State] = 'AVAILABLE')
    BEGIN
        SET @ResultMessage = 'No available user found with this ID.';
        RETURN;
    END;

    -- Update only provided fields
    UPDATE SystemUser
    SET
        [Password] = ISNULL(@Password, [Password]),
        Bio = ISNULL(@Bio, Bio),
        BankAccount = ISNULL(@BankAccount, BankAccount),
        ProfileName = ISNULL(@ProfileName, ProfileName),
        ProfilePhoto = ISNULL(@ProfilePhoto, ProfilePhoto)
    WHERE UserID = @UserID;

    SET @ResultMessage = 'Success';
END;
-----------------------------------------------------------------------------------------------
-- User can login for his account if exist by the mail and password
-- passing the role can help to specify the page after login

-- sp_LoginUser
CREATE PROCEDURE sp_LoginUser
    @Mail VARCHAR(100),
    @Password VARCHAR(100),
    @UserID INT OUTPUT,
    @UserRole VARCHAR(50) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check User data
    SELECT 
        @UserID = usr.UserID,
        @UserRole = r.RoleName
    FROM
        SystemUser usr
    INNER JOIN
        Role r ON r.RoleID = usr.RoleID
    WHERE
        usr.Mail = @Mail
        AND usr.[Password] = @Password
        AND usr.[State] = 'AVAILABLE';

    -- Check if login succeeded
    IF @UserID IS NULL
        SET @ResultMessage = 'Failed: Invalid credentials or inactive user';
    ELSE
        SET @ResultMessage = 'Success';
END;
--------------------------------------------------------------------------------
-- User create an account for the first time

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
    END;

    -- Handle default ProfileName if NULL
    IF @ProfileName IS NULL
        SET @ProfileName = @FirstName + ' ' + @LastName;

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
        GETDATE(),
        @RoleID,
        'AVAILABLE'
    );

    SET @ResultMessage = 'Success';
END;