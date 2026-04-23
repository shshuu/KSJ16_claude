<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,com.nucleus.util.DBConn,com.nucleus.util.PasswordUtil" %>
<%
request.setCharacterEncoding("UTF-8");

String userId = request.getParameter("userId");
String userPw = request.getParameter("userPw");

Integer roleNum = null;
String roleDescription = null;
Integer userNum = null;
String errorMessage = null;

Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DBConn.getConnection();

    pstmt = conn.prepareStatement(
        "SELECT u.user_id, u.user_num, ur.role_num, r.role_description " +
        "FROM nc_user u " +
        "LEFT JOIN nc_user_role ur ON ur.user_id = u.user_id " +
        "LEFT JOIN nc_role r ON r.role_num = ur.role_num " +
        "WHERE u.user_id = ? AND u.user_pw = ?"
    );

    pstmt.setString(1, userId);
    pstmt.setString(2, PasswordUtil.hash(userPw));
    rs = pstmt.executeQuery();

    if (rs.next()) {
        userNum = rs.getInt("user_num");
        roleNum = rs.getInt("role_num");
        roleDescription = rs.getString("role_description");
    } else {
        errorMessage = "아이디 또는 비밀번호가 올바르지 않습니다.";
    }
} catch (Exception e) {
    e.printStackTrace();
    errorMessage = "로그인 처리 중 오류가 발생했습니다.";
} finally {
    DBConn.close(rs);
    DBConn.close(pstmt);
    DBConn.close(conn);
}

if (roleNum != null) {
    session.setAttribute("loginId", userId);
    session.setAttribute("userNum", userNum);
    session.setAttribute("roleNum", roleNum);
    session.setAttribute("roleDescription", roleDescription);
    response.sendRedirect("main.jsp");
    return;
}

if (errorMessage == null || errorMessage.trim().isEmpty()) {
    errorMessage = "로그인에 실패했습니다.";
}

errorMessage = errorMessage
    .replace("\\", "\\\\")
    .replace("\"", "\\\"")
    .replace("\r", "")
    .replace("\n", "\\n");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>로그인 실패</title>
</head>
<body>
<script>
    alert("<%= errorMessage %>");
    location.href = "login.jsp";
</script>
</body>
</html>
