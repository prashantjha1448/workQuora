const aiProvider = require('../services/aiProvider');

/**
 * Parses raw job description and extracts matching skill keywords using AI Provider abstraction.
 */
exports.extractSkillsFromText = async (description) => {
  try {
    const prompt = `Analyze the following job description or user requirement for a local service marketplace. 
    Extract a list of relevant professional skills, tools, or service categories needed to complete this work.
    
    Return the output STRICTLY as a JSON array of strings in lowercase. Do not include any explanation or extra text.
    
    Example Input: "Mera geyser kharab ho gya h paani garam nhi kr rha urgent koi aao fixed krne"
    Example Output: ["plumber", "geyser repair", "appliance repair", "electrician"]
    
    Current Job Description: "${description}"`;

    const responseText = await aiProvider.generate(prompt);
    
    // Attempt parsing JSON
    try {
      // Find JSON block if Gemini returned markdown wrap
      const jsonStart = responseText.indexOf('[');
      const jsonEnd = responseText.lastIndexOf(']') + 1;
      if (jsonStart !== -1 && jsonEnd !== -1) {
        return JSON.parse(responseText.substring(jsonStart, jsonEnd));
      }
      return JSON.parse(responseText);
    } catch (e) {
      // Regex parse fallback if it is a list of comma words
      return responseText.replace(/[\[\]"]/g, '').split(',').map(s => s.trim().toLowerCase());
    }
  } catch (error) {
    console.error("🤖 AI Parsing Error, falling back to basic regex array:", error);
    return description.toLowerCase().split(' ').filter(word => word.length > 3);
  }
};