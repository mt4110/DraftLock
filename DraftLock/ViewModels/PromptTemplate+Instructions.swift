import Foundation

extension PromptTemplate {
    func instructions(for input: String) -> String {
        let mirror = Mirror(reflecting: self)
        
        var systemPrompt: String?
        var templatePrompt: String?
        
        for child in mirror.children {
            if let label = child.label {
                if label == "systemPrompt", let value = child.value as? String, !value.isEmpty {
                    systemPrompt = value
                } else if (label == "prompt" || label == "body"),
                          let value = child.value as? String, !value.isEmpty {
                    templatePrompt = value
                }
            }
        }
        
        if systemPrompt == nil && templatePrompt == nil {
            return "Follow the template to process the input and produce a helpful, concise result."
        }
        
        var components = [String]()
        
        if let system = systemPrompt {
            components.append("System:\n\(system)")
        }
        
        if let template = templatePrompt {
            components.append("Template:\n\(template)")
        }
        
        components.append("Guidance:\nUse the template above to transform the provided input.")
        
        return components.joined(separator: "\n\n")
    }
}
