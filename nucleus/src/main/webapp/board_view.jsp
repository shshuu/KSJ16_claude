<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,com.nucleus.util.DBConn" %>
<%
String loginId = (String) session.getAttribute("loginId");
if (loginId == null) {
    response.sendRedirect("login.jsp");
    return;
}

String postId = request.getParameter("postId");
if (postId == null || postId.trim().isEmpty()) {
    response.sendRedirect("board_list.jsp");
    return;
}

String title = "";
String author = "";
String contents = "";
String createdAt = "";
String updatedAt = "";
String fileName = "";
boolean hasFile = false;
String errorMessage = null;

Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DBConn.getConnection();
    pstmt = conn.prepareStatement(
        "SELECT n.nt_id, n.user_id, n.title, n.contents, n.created_at, n.updated_at, " +
        "f.file_id, f.real_name " +
        "FROM nc_notice n " +
        "LEFT JOIN nc_file f ON n.nc_file_id = f.file_id " +
        "WHERE n.nt_id = ?"
    );
    pstmt.setInt(1, Integer.parseInt(postId));
    rs = pstmt.executeQuery();

    if (rs.next()) {
        title = rs.getString("title");
        author = rs.getString("user_id");
        contents = rs.getString("contents");
        createdAt = String.valueOf(rs.getTimestamp("created_at"));
        updatedAt = String.valueOf(rs.getTimestamp("updated_at"));
        fileName = rs.getString("real_name");
        hasFile = (rs.getObject("file_id") != null);
    } else {
        response.sendRedirect("board_list.jsp");
        return;
    }
} catch (Exception e) {
    errorMessage = e.getMessage();
} finally {
    DBConn.close(rs);
    DBConn.close(pstmt);
    DBConn.close(conn);
}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>게시글 확인</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">게시글 확인</h1>
        <p class="page-subtitle">일반 사용자는 게시글 조회와 첨부파일 다운로드만 가능합니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='board_list.jsp'">목록으로</button>
      </div>
    </header>

    <section class="board-view">
      <h2><%= title %></h2>
      <div class="board-meta">
        <span>게시글 번호: <strong><%= postId %></strong></span>
        <span>작성자: <strong><%= author %></strong></span>
        <span>등록일: <strong><%= createdAt %></strong></span>
        <span>수정일: <strong><%= updatedAt %></strong></span>
      </div>
      <div class="board-body"><%= errorMessage == null ? contents : "DB 조회 중 오류가 발생했습니다." %></div>
      <div class="file-box">
        <strong>첨부파일</strong>
        <p class="muted"><%= fileName == null || fileName.trim().isEmpty() ? "첨부파일이 없습니다." : fileName %></p>
        <% if (hasFile) { %>
        <a class="btn btn-secondary" href="board-download?postId=<%= postId %>">첨부파일 다운로드</a>
        <% } %>
      </div>
    </section>
  </div>
</body>
</html>
