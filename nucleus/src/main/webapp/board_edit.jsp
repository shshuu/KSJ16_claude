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
String contents = "";
String fileName = "";
String errorMessage = request.getParameter("error");
if (errorMessage != null) {
    errorMessage = URLDecoder.decode(errorMessage, "UTF-8");
}

Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;
try {
    conn = DBConn.getConnection();
    pstmt = conn.prepareStatement(
        "SELECT n.title, n.contents, f.real_name " +
        "FROM nc_notice n LEFT JOIN nc_file f ON n.nc_file_id = f.file_id " +
        "WHERE n.nt_id = ?"
    );
    pstmt.setInt(1, Integer.parseInt(postId));
    rs = pstmt.executeQuery();
    if (rs.next()) {
        title = rs.getString("title");
        contents = rs.getString("contents");
        fileName = rs.getString("real_name");
    } else {
        response.sendRedirect("board_list_admin.jsp");
        return;
    }
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
  <title>게시글 수정</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">게시글 수정</h1>
        <p class="page-subtitle">수정 버튼을 눌렀을 때만 들어오는 별도 수정 페이지입니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='board_admin.jsp?postId=<%= postId %>'">게시글 관리 화면</button>
      </div>
    </header>

    <% if (errorMessage != null) { %>
    <div class="notice" style="margin-bottom:20px; background:#fee4e2; color:#b42318; border-color:#f6c7c3;"><%= errorMessage %></div>
    <% } %>

    <section class="card">
      <form class="form-grid" method="post" action="board-manage" enctype="multipart/form-data">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="postId" value="<%= postId %>">
        <div class="field">
          <label for="title">제목</label>
          <input id="title" name="title" value="<%= title %>" maxlength="45" required>
        </div>
        <div class="field">
          <label for="contents">내용</label>
          <textarea id="contents" name="contents" required><%= contents %></textarea>
        </div>
        <div class="field">
          <label for="uploadFile">첨부파일</label>
          <input id="uploadFile" name="uploadFile" type="file">
        </div>
        <div class="file-box">
          <strong>현재 첨부파일</strong>
          <p class="muted"><%= fileName == null || fileName.trim().isEmpty() ? "첨부파일이 없습니다." : fileName %></p>
        </div>
        <div class="actions">
          <button class="btn btn-primary" type="submit">수정 저장</button>
          <button class="btn btn-ghost" type="button" onclick="location.href='board_admin.jsp?postId=<%= postId %>'">취소</button>
        </div>
      </form>
    </section>
  </div>
</body>
</html>
