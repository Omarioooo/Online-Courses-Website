-- sp_GetAllCategories
ALTER PROCEDURE sp_GetAllCategories
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all categories
    SELECT CategoryType
    FROM Category;

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No categories found.';
    ELSE
        SET @ResultMessage = 'Success';
END;