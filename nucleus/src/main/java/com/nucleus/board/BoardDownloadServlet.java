package com.nucleus.board;

import com.nucleus.util.DBConn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/board-download")
public class BoardDownloadServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String loginId = (String) request.getSession().getAttribute("loginId");
        if (loginId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String postId = request.getParameter("postId");
        if (postId == null || postId.trim().isEmpty()) {
            response.sendRedirect("board_list.jsp");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBConn.getConnection();
            pstmt = conn.prepareStatement(
                "SELECT f.real_name, f.path FROM nc_notice n " +
                "INNER JOIN nc_file f ON f.file_id = n.nc_file_id " +
                "WHERE n.nt_id = ?"
            );
            pstmt.setInt(1, Integer.parseInt(postId));
            rs = pstmt.executeQuery();

            if (!rs.next()) {
                response.sendRedirect("board_view.jsp?postId=" + postId);
                return;
            }

            String realName = rs.getString("real_name");
            String filePath = rs.getString("path");
            File file = new File(filePath);
            if (!file.exists()) {
                response.sendRedirect("board_view.jsp?postId=" + postId);
                return;
            }

            response.setContentType("application/octet-stream");
            response.setContentLengthLong(file.length());
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"" + URLEncoder.encode(realName, StandardCharsets.UTF_8).replace("+", "%20") + "\""
            );

            try (FileInputStream fis = new FileInputStream(file); OutputStream os = response.getOutputStream()) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = fis.read(buffer)) != -1) {
                    os.write(buffer, 0, read);
                }
                os.flush();
            }
        } catch (Exception e) {
            throw new ServletException(e);
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
            DBConn.close(conn);
        }
    }
}
