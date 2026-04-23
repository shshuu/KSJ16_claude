package com.nucleus.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class DBConn {
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";
    private static final String HOST = "192.168.0.131";
    private static final String PORT = "3306";
    private static final String DATABASE = "nucleus_db";

    // TODO: 운영 환경에서는 별도 설정 파일로 분리하는 편이 안전합니다.
    private static final String USER = "nc_user";
    private static final String PASSWORD = "nucleus123";

    private static final String URL =
        "jdbc:mysql://" + HOST + ":" + PORT + "/" + DATABASE
        + "?serverTimezone=Asia/Seoul"
        + "&characterEncoding=UTF-8"
        + "&useSSL=false"
        + "&allowPublicKeyRetrieval=true";

    private DBConn() {
    }

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        Class.forName(DRIVER);
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    public static void close(AutoCloseable resource) {
        if (resource == null) {
            return;
        }

        try {
            resource.close();
        } catch (Exception ignored) {
        }
    }
}
