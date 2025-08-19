-- sp_GetAllUsers
CREATE PROCEDURE sp_GetAllUsers
    @ResultMessage VARCHAR(10) OUTPUT
AS
BEGIN
   -- Stop tracking of the num of affected rows
   SET NOCOUNT ON;

   -- Check if there are any users
   IF EXISTS (SELECT 1 FROM SystemUser WHERE [State] = 'AVAILABLE')
    BEGIN
        SELECT *
        FROM SystemUser
		WHERE [State] = 'AVAILABLE'

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
    @ResultMessage VARCHAR(10) OUTPUT
AS
BEGIN
    -- Stop tracking of the number of affected rows
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [Role] WHERE RoleID = @RoleID)
    BEGIN
        SELECT *
        FROM SystemUser
        WHERE RoleID = @RoleID;

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
-- sp_DeleteUser