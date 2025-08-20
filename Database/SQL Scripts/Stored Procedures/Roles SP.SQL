-- sp_GetAllRoles
CREATE PROCEDURE sp_GetAllRoles
     @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
   SELECT RoleName
   FROM [Role]

   SET @ResultMessage = 'Done'
END;