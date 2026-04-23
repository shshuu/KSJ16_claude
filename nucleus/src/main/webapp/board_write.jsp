<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLDecoder" %>
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

String errorMessage = request.getParameter("error");
if (errorMessage != null) {
    errorMessage = URLDecoder.decode(errorMessage, "UTF-8");
}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>게시글 작성</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">게시글 작성</h1>
        <p class="page-subtitle">관리자 권한으로 새 게시글을 등록합니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='board_list_admin.jsp'">관리자 게시판 목록</button>
      </div>
    </header>

    <% if (errorMessage != null) { %>
    <div class="notice" style="margin-bottom:20px; background:#fee4e2; color:#b42318; border-color:#f6c7c3;"><%= errorMessage %></div>
    <% } %>

    <section class="card">
      <form class="form-grid" method="post" action="board-manage" enctype="multipart/form-data">
        <input type="hidden" name="action" value="create">
        <div class="field">
          <label for="title">제목</label>
          <input id="title" name="title" maxlength="45" required>
        </div>
        <div class="field">
          <label for="contents">내용</label>
          <textarea id="contents" name="contents" required></textarea>
        </div>
        <div class="field">
          <label for="uploadFile">첨부파일</label>
          <input id="uploadFile" name="uploadFile" type="file">
        </div>
        <div class="actions">
          <button class="btn btn-primary" type="submit">등록</button>
          <button class="btn btn-ghost" type="button" onclick="location.href='board_list_admin.jsp'">취소</button>
        </div>
      </form>
    </section>
  </div>
</body>
</html>
