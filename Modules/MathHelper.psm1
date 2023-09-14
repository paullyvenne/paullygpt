function Get-CosineSimilarityScore {
    param (
        [string]$sentence1,
        [string]$sentence2
    )

    # Tokenize the sentences
    $tokens1 = $sentence1.ToLower().Split(' ')
    $tokens2 = $sentence2.ToLower().Split(' ')

    # Create a set of unique tokens from both sentences
    $uniqueTokens = $tokens1 + $tokens2 | Select-Object -Unique

    # Build term frequency vectors for both sentences
    $vector1 = @{}
    $vector2 = @{}

    foreach ($token in $uniqueTokens) {
        $vector1[$token] = $tokens1 | Where-Object { $_ -eq $token } | Measure-Object | Select-Object -ExpandProperty Count
        $vector2[$token] = $tokens2 | Where-Object { $_ -eq $token } | Measure-Object | Select-Object -ExpandProperty Count
    }

    # Calculate the dot product of the term frequency vectors
    $dotProduct = 0
    foreach ($token in $uniqueTokens) {
        $dotProduct += $vector1[$token] * $vector2[$token]
    }

    # Calculate the magnitudes of the term frequency vectors
    $magnitude1 = [Math]::Sqrt(($vector1.Values | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)
    $magnitude2 = [Math]::Sqrt(($vector2.Values | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)

    # Calculate the cosine similarity score
    $score = $dotProduct / ($magnitude1 * $magnitude2)

    return $score
}

# Example usage:
# $sentence1 = "The cat is black"
# $sentence2 = "The dog is black"

# $score = Get-CosineSimilarityScore -sentence1 $sentence1 -sentence2 $sentence2
# Write-Output "Cosine similarity score: $score"