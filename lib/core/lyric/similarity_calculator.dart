import 'dart:math';

class SimilarityCalculator {
  static double calculateSimilarity(String s1, String s2) {
    final str1 = s1.trim().toLowerCase();
    final str2 = s2.trim().toLowerCase();

    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final distance = _levenshtein(str1, str2);
    final maxLen = max(str1.length, str2.length);
    return 1.0 - (distance / maxLen);
  }

  static int _levenshtein(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        dp[i][j] = min(
          dp[i - 1][j] + 1,
          min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }

    return dp[m][n];
  }
}
