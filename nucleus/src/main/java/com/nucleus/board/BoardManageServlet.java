package com.nucleus.board;

import com.nucleus.util.DBConn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@WebServlet("/board-manage")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class BoardManageServlet extends HttpServlet {
    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<String>(
        Arrays.asList("pdf", "jpg", "jpeg", "png", "doc", "docx", "xls", "xlsx", "gif")
    );

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String loginId = (String) request.getSession().getAttribute("loginId");
        Integer roleNum = (Integer) request.getSession().getAttribute("roleNum");
        if (loginId == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (roleNum == null || (roleNum != 1 && roleNum != 2)) {
            response.sendRedirect("ad_check.jsp");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("delete".equals(action)) {
                deletePost(request, response);
            } else if ("update".equals(action)) {
                updatePost(request, response, loginId);
            } else {
                createPost(request, response, loginId);
            }
        } catch (Exception e) {
            String postId = request.getParameter("postId");
            String target;
            if ("update".equals(action)) {
                target = "board_edit.jsp?postId=" + postId;
            } else if ("create".equals(action) || action == null || action.trim().isEmpty()) {
                target = "board_write.jsp";
            } else {
                target = (postId == null || postId.trim().isEmpty()) ? "board_list_admin.jsp" : "board_admin.jsp?postId=" + postId;
            }
            response.sendRedirect(target + (target.contains("?") ? "&" : "?") + "error=" + encode(e.getMessage()));
        }
    }

    private void createPost(HttpServletRequest request, HttpServletResponse response, String loginId) throws Exception {
        String title = trim(request.getParameter("title"));
        String contents = trim(request.getParameter("contents"));
        if (title.isEmpty() || contents.isEmpty()) {
            response.sendRedirect("board_write.jsp?error=" + encode("제목과 내용을 모두 입력해주세요."));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            Integer fileId = saveUploadedFile(request, conn);
            pstmt = conn.prepareStatement(
                "INSERT INTO nc_notice (user_id, title, contents, created_at, updated_at, nc_file_id) " +
                "VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            pstmt.setString(1, loginId);
            pstmt.setString(2, title);
            pstmt.setString(3, contents);
            if (fileId == null) {
                pstmt.setNull(4, java.sql.Types.INTEGER);
            } else {
                pstmt.setInt(4, fileId);
            }
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();

            int postId = 0;
            if (rs.next()) {
                postId = rs.getInt(1);
            }

            conn.commit();
            response.sendRedirect("board_admin.jsp?postId=" + postId + "&success=" + encode("게시글이 등록되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private void updatePost(HttpServletRequest request, HttpServletResponse response, String loginId) throws Exception {
        String postId = trim(request.getParameter("postId"));
        String title = trim(request.getParameter("title"));
        String contents = trim(request.getParameter("contents"));
        if (postId.isEmpty()) {
            response.sendRedirect("board_list_admin.jsp");
            return;
        }
        if (title.isEmpty() || contents.isEmpty()) {
            response.sendRedirect("board_edit.jsp?postId=" + postId + "&error=" + encode("제목과 내용을 모두 입력해주세요."));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            Integer currentFileId = null;
            String currentFilePath = null;
            pstmt = conn.prepareStatement(
                "SELECT n.nc_file_id, f.path FROM nc_notice n " +
                "LEFT JOIN nc_file f ON f.file_id = n.nc_file_id " +
                "WHERE n.nt_id = ?"
            );
            pstmt.setInt(1, Integer.parseInt(postId));
            rs = pstmt.executeQuery();
            if (rs.next()) {
                currentFileId = (Integer) rs.getObject("nc_file_id");
                currentFilePath = rs.getString("path");
            }
            DBConn.close(rs);
            DBConn.close(pstmt);
            rs = null;
            pstmt = null;

            Integer newFileId = saveUploadedFile(request, conn);
            Integer targetFileId = newFileId != null ? newFileId : currentFileId;

            pstmt = conn.prepareStatement(
                "UPDATE nc_notice SET user_id = ?, title = ?, contents = ?, updated_at = CURRENT_TIMESTAMP, nc_file_id = ? " +
                "WHERE nt_id = ?"
            );
            pstmt.setString(1, loginId);
            pstmt.setString(2, title);
            pstmt.setString(3, contents);
            if (targetFileId == null) {
                pstmt.setNull(4, java.sql.Types.INTEGER);
            } else {
                pstmt.setInt(4, targetFileId);
            }
            pstmt.setInt(5, Integer.parseInt(postId));
            pstmt.executeUpdate();
            DBConn.close(pstmt);
            pstmt = null;

            if (newFileId != null && currentFileId != null) {
                deleteFileRecord(conn, currentFileId, currentFilePath);
            }

            conn.commit();
            response.sendRedirect("board_admin.jsp?postId=" + postId + "&success=" + encode("게시글이 수정되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private void deletePost(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String postId = trim(request.getParameter("postId"));
        if (postId.isEmpty()) {
            response.sendRedirect("board_list_admin.jsp");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            Integer fileId = null;
            String filePath = null;
            pstmt = conn.prepareStatement(
                "SELECT n.nc_file_id, f.path FROM nc_notice n " +
                "LEFT JOIN nc_file f ON f.file_id = n.nc_file_id " +
                "WHERE n.nt_id = ?"
            );
            pstmt.setInt(1, Integer.parseInt(postId));
            rs = pstmt.executeQuery();
            if (rs.next()) {
                fileId = (Integer) rs.getObject("nc_file_id");
                filePath = rs.getString("path");
            }
            DBConn.close(rs);
            DBConn.close(pstmt);
            rs = null;
            pstmt = null;

            pstmt = conn.prepareStatement("DELETE FROM nc_notice WHERE nt_id = ?");
            pstmt.setInt(1, Integer.parseInt(postId));
            pstmt.executeUpdate();
            DBConn.close(pstmt);
            pstmt = null;

            if (fileId != null) {
                deleteFileRecord(conn, fileId, filePath);
            }

            conn.commit();
            response.sendRedirect("board_list_admin.jsp?success=" + encode("게시글이 삭제되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private Integer saveUploadedFile(HttpServletRequest request, Connection conn) throws Exception {
        Part filePart = request.getPart("uploadFile");
        if (filePart == null || filePart.getSize() == 0) {
            return null;
        }

        String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
        String extension = "";
        int dotIndex = originalFileName.lastIndexOf('.');
        if (dotIndex >= 0 && dotIndex < originalFileName.length() - 1) {
            extension = originalFileName.substring(dotIndex + 1).toLowerCase(Locale.ROOT);
        }
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IllegalArgumentException("허용되지 않는 파일 형식입니다.");
        }

        String storedFileName = UUID.randomUUID() + "_" + originalFileName;
        String uploadDir = getServletContext().getRealPath("/WEB-INF/uploads");
        File uploadFolder = new File(uploadDir);
        if (!uploadFolder.exists()) {
            uploadFolder.mkdirs();
        }

        Path savedPath = Paths.get(uploadDir, storedFileName);
        Files.copy(filePart.getInputStream(), savedPath, StandardCopyOption.REPLACE_EXISTING);

        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            pstmt = conn.prepareStatement(
                "INSERT INTO nc_file (name, real_name, path, uploaded_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
                Statement.RETURN_GENERATED_KEYS
            );
            pstmt.setString(1, storedFileName);
            pstmt.setString(2, originalFileName);
            pstmt.setString(3, savedPath.toString());
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) {
                return rs.getInt(1);
            }
            return null;
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
        }
    }

    private void deleteFileRecord(Connection conn, Integer fileId, String filePath) throws Exception {
        PreparedStatement pstmt = null;
        try {
            pstmt = conn.prepareStatement("DELETE FROM nc_file WHERE file_id = ?");
            pstmt.setInt(1, fileId);
            pstmt.executeUpdate();
        } finally {
            DBConn.close(pstmt);
        }
        if (filePath != null && !filePath.trim().isEmpty()) {
            Files.deleteIfExists(Paths.get(filePath));
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String encode(String value) {
        return java.net.URLEncoder.encode(value == null ? "" : value, java.nio.charset.StandardCharsets.UTF_8);
    }
}
