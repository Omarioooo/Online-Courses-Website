-- sp_GetAllRoles
CREATE PROCEDURE sp_GetAllRoles
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all roles
    SELECT RoleName
    FROM [Role];

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No roles found.';
    ELSE
        SET @ResultMessage = 'Success';
END;