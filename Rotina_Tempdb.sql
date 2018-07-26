/*
	Objetivo: Monitorar o uso da tempdb
	Fonte: https://docs.microsoft.com/pt-br/sql/relational-databases/databases/tempdb-database?view=sql-server-2017
		   https://docs.microsoft.com/pt-br/previous-versions/sql/sql-server-2008-r2/ms176029(v=sql.105)
*/

SELECT name AS FileName, 
   size*1.0/128 AS FileSizeinMB,
   CASE max_size 
       WHEN 0 THEN 'Autogrowth is off.'
       WHEN -1 THEN 'Autogrowth is on.'
       ELSE 'Log file grows to a maximum size of 2 TB.'
   END,
   growth AS 'GrowthValue',
   'GrowthIncrement' = 
       CASE
           WHEN growth = 0 THEN 'Size is fixed.'
           WHEN growth > 0 AND is_percent_growth = 0 
               THEN 'Growth value is in 8-KB pages.'
           ELSE 'Growth value is a percentage.'
       END
FROM tempdb.sys.database_files;
GO

-- Determining the Amount of Free Space in tempdb
SELECT SUM(unallocated_extent_page_count) AS [free pages], 
 (SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount Space Used by the Version Store
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
 (SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by Internal Objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
 (SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by User Objects
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
 (SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;

-- Obtaining the space consumed by internal objects in all currently running tasks in each session
SELECT session_id, 
 SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
 SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
FROM sys.dm_db_task_space_usage 
GROUP BY session_id;

-- Obtaining the space consumed by internal objects in the current session for both running and completed tasks
SELECT R2.session_id,
 R1.internal_objects_alloc_page_count 
 + SUM(R2.internal_objects_alloc_page_count) AS session_internal_objects_alloc_page_count,
 R1.internal_objects_dealloc_page_count 
 + SUM(R2.internal_objects_dealloc_page_count) AS session_internal_objects_dealloc_page_count
FROM sys.dm_db_session_space_usage AS R1 
INNER JOIN sys.dm_db_task_space_usage AS R2 ON R1.session_id = R2.session_id
GROUP BY R2.session_id, R1.internal_objects_alloc_page_count, 
 R1.internal_objects_dealloc_page_count;;

SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;