-- sp_GetAllUsers
CREATE PROCEDURE sp_GetAllUsers
    @ResultMessage VARCHAR(10) OUTPUT
AS
BEGIN
   -- Stop tracking of the num of affected rows
   SET NOCOUNT ON;

   -- Check if there are any users
   IF EXISTS (SELECT 1 FROM SystemUser)
    BEGIN
        SELECT *
        FROM SystemUser

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