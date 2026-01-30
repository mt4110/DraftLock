struct DraftPrompt {

    static func forMode(_ mode: DraftMode, input: String) -> String {
        switch mode {
        case .chat:
            return chat(input)
        case .doc:
            return doc(input)
        case .pr:
            return pr(input)
        }
    }

    // MARK: - Modes

    private static func chat(_ input: String) -> String {
        """
        You are rewriting text for Slack communication.

        Constraints:
        - Put the conclusion first.
        - Each sentence must be under 40 characters.
        - Background explanation: max 2 sentences.
        - Remove emotional language and self-justification.

        Input:
        \(input)
        """
    }

    private static func doc(_ input: String) -> String {
        """
        Reorganize the following text into the sections below.

        Sections:
        - Background
        - Issue
        - Decision
        - Next Action

        Rules:
        - Separate facts from opinions.
        - Remove vague expressions.

        Input:
        \(input)
        """
    }

    private static func pr(_ input: String) -> String {
        """
        Convert the following text into a GitHub Pull Request description.

        Extract and structure:
        - What
        - Why
        - How
        - Risk
        - Test

        Input:
        \(input)
        """
    }
}
