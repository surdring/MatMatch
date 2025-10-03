-- Oracle数据库只读用户创建脚本
-- 目标数据库: dhnc65
-- 用途: 为智能物料查重工具提供安全的只读数据访问

-- 1. 创建只读用户
CREATE USER matmatch_read IDENTIFIED BY "matmatch_read";

-- 2. 授予基本连接权限
GRANT CREATE SESSION TO matmatch_read;

-- 3. 授予对物料相关表的只读权限
-- 请根据实际表名替换以下表名
GRANT SELECT ON dhnc65.bd_material TO matmatch_read;
GRANT SELECT ON dhnc65.BD_MEASDOC TO matmatch_read;


-- 4. 授予查询数据字典的权限（可选，便于调试）
GRANT SELECT ANY DICTIONARY TO matmatch_read;

-- 5. 设置用户配额（限制为最小）
ALTER USER matmatch_read QUOTA 1M ON USERS;

-- 6. 设置密码策略
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;

-- 7. 验证用户权限
-- 执行以下查询验证权限是否正确授予
SELECT * FROM session_privs WHERE username = 'matmatch_read';

-- 8. 查看用户权限详情
SELECT * FROM dba_tab_privs WHERE grantee = 'matmatch_read';