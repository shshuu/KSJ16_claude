<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.net.URLDecoder,com.nucleus.util.DBConn" %>
<%
String loginId = (String) session.getAttribute("loginId");
Integer roleNum = (Integer) session.getAttribute("roleNum");
if (loginId == null) {
    response.sendRedirect("login.jsp");
    return;
}
if (roleNum == null || (roleNum != 1 && roleNum != 2)) {
    response.sendRedirect("ad_check.jsp");
    return;
}

String postId = request.getParameter("postId");
if (postId == null || postId.trim().isEmpty()) {
    response.sendRedirect("board_list_admin.jsp");
    return;
}

String title = "";
String author = "";
String contents = "";
String createdAt = "";
String updatedAt = "";
String fileName = "";
boolean hasFile = false;

String successMessage = request.getParameter("success");
String errorMessage = request.getParameter("error");
if (successMessage != null) {
    successMessage = URLDecoder.decode(successMessage, "UTF-8");
}
if (errorMessage != null) {
    errorMessage = URLDecoder.decode(errorMessage, "UTF-8");
}

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
        response.sendRedirect("board_list_admin.jsp");
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
  <title>게시글 관리</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">게시글 관리</h1>
        <p class="page-subtitle">일반 사용자 상세 화면과 동일하게 보되, 관리자 전용 작업 버튼을 추가한 화면입니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='board_list_admin.jsp'">관리자 게시판 목록</button>
      </div>
    </header>

    <% if (successMessage != null) { %>
    <div class="notice" style="margin-bottom:20px;"><%= successMessage %></div>
    <% } %>
    <% if (errorMessage != null) { %>
    <div class="notice" style="margin-bottom:20px; background:#fee4e2; color:#b42318; border-color:#f6c7c3;"><%= errorMessage %></div>
    <% } %>

    <section class="board-view">
      <h2><%= title %></h2>
      <div class="board-meta">
        <span>게시글 번호: <strong><%= postId %></strong></span>
        <span>작성자: <strong><%= author %></strong></span>
        <span>등록일: <strong><%= createdAt %></strong></span>
        <span>수정일: <strong><%= updatedAt %></strong></span>
      </div>
      <div class="board-body"><%= contents %></div>
      <div class="file-box">
        <strong>첨부파일</strong>
        <p class="muted"><%= fileName == null || fileName.trim().isEmpty() ? "첨부파일이 없습니다." : fileName %></p>
        <div class="actions">
          <% if (hasFile) { %>
          <a class="btn btn-secondary" href="board-download?postId=<%= postId %>">첨부파일 다운로드</a>
          <% } %>
          <button class="btn btn-primary" type="button" onclick="location.href='board_write.jsp'">글 작성</button>
          <button class="btn btn-ghost" type="button" onclick="location.href='board_edit.jsp?postId=<%= postId %>'">수정</button>
          <form method="post" action="board-manage" onsubmit="return confirm('이 게시글을 삭제하시겠습니까?');">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="postId" value="<%= postId %>">
            <button class="btn btn-danger" type="submit">삭제</button>
          </form>
        </div>
      </div>
    </section>
  </div>
</body>
</html>
