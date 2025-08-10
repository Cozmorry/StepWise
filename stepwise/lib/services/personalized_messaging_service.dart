import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizedMessagingService {
  static Future<String> getPersonalizedMessage(UserProfile profile, int currentSteps, int dailyGoal) async {
    final bmiCategory = profile.bmiCategory;
    final age = profile.age;
    final gender = profile.gender.toLowerCase();
    final progressPercentage = (currentSteps / dailyGoal * 100).round();
    
    // Get daily seed for message variation
    final dailySeed = await _getDailySeed();
    
    // Base messages by BMI category with daily variation
    String baseMessage = _getBaseMessageByBMI(bmiCategory, age, gender, dailySeed);
    
    // Add step progress context with daily variation
    String progressMessage = _getProgressMessage(progressPercentage, bmiCategory, dailySeed);
    
    // Add motivational element with daily variation
    String motivationalMessage = _getMotivationalMessage(bmiCategory, age, gender, dailySeed);
    
    return '$baseMessage\n\n$progressMessage\n\n$motivationalMessage';
  }
  
  static Future<int> _getDailySeed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastMessageDate = prefs.getString('last_personalized_message_date');
    
    // If it's a new day, generate a new seed
    if (lastMessageDate != todayKey) {
      final newSeed = today.millisecondsSinceEpoch % 1000; // Simple seed based on date
      await prefs.setString('last_personalized_message_date', todayKey);
      await prefs.setInt('daily_message_seed', newSeed);
      return newSeed;
    }
    
    // Return existing seed for today
    return prefs.getInt('daily_message_seed') ?? 0;
  }
  
  static String _getBaseMessageByBMI(String bmiCategory, int age, String gender, int dailySeed) {
    switch (bmiCategory) {
      case 'Underweight':
        if (age < 25) {
          final messages = gender == 'male' 
            ? [
                "Hey there! I notice you're on the lighter side. Building healthy muscle mass through regular walking and strength training can help you reach a healthy weight while improving your overall fitness.",
                "Hi! I see you're underweight. Walking regularly combined with strength training is a great way to build healthy muscle mass and reach your ideal weight naturally.",
                "Good morning! I notice you're underweight. Regular physical activity like walking can help boost your appetite and metabolism, supporting healthy weight gain."
              ]
            : [
                "Hi! I see you're underweight. Regular walking combined with strength training can help you build healthy muscle mass and reach your ideal weight naturally.",
                "Hello! I notice you're on the lighter side. Walking regularly is a gentle way to build strength and improve your overall fitness while working toward a healthy weight.",
                "Good day! I see you're underweight. Regular walking can help boost your metabolism and appetite, making it easier to reach your healthy weight goals."
              ];
          return messages[dailySeed % messages.length];
        } else {
          final messages = [
            "I understand maintaining a healthy weight can be challenging. Regular walking helps boost your metabolism and appetite naturally, supporting healthy weight gain.",
            "I know weight management can be difficult. Walking regularly can help stimulate your appetite and metabolism, making healthy weight gain more achievable.",
            "I understand the challenges of maintaining a healthy weight. Regular walking is a gentle way to boost your metabolism and support healthy weight gain."
          ];
          return messages[dailySeed % messages.length];
        }
        
      case 'Normal weight':
        if (age < 30) {
          final messages = [
            "Great job maintaining a healthy weight! Your current BMI is in the ideal range. Keep up the excellent work with regular physical activity.",
            "Excellent work! You're maintaining a healthy weight perfectly. Your dedication to regular walking is paying off in your overall fitness.",
            "Fantastic! You're in the ideal weight range. Keep up your great walking routine - it's maintaining your health beautifully."
          ];
          return messages[dailySeed % messages.length];
        } else if (age < 50) {
          final messages = [
            "Excellent! You're maintaining a healthy weight for your age. Regular walking helps preserve muscle mass and bone density as you age.",
            "Great job! You're keeping a healthy weight as you age. Regular walking is helping preserve your muscle mass and bone health.",
            "Wonderful! You're maintaining a healthy weight for your age group. Your walking routine is helping preserve your strength and mobility."
          ];
          return messages[dailySeed % messages.length];
        } else {
          final messages = [
            "Fantastic! Maintaining a healthy weight at your age is crucial for overall health. Walking helps maintain mobility and cardiovascular health.",
            "Excellent! You're maintaining a healthy weight which is so important at your age. Walking regularly is keeping you mobile and healthy.",
            "Great work! Maintaining a healthy weight as you age is vital. Your walking routine is supporting your mobility and heart health."
          ];
          return messages[dailySeed % messages.length];
        }
        
      case 'Overweight':
        if (age < 35) {
          final messages = gender == 'male'
            ? [
                "I see you're working on your fitness journey. Walking is one of the best ways to start - it's gentle on your joints while effectively burning calories.",
                "You're making great progress on your fitness journey! Walking is perfect for weight management - it's sustainable and effective.",
                "I can see your dedication to improving your health. Walking is an excellent choice for weight management - it's gentle yet effective."
              ]
            : [
                "You're taking great steps toward better health! Walking is perfect for weight management - it's sustainable and enjoyable.",
                "I see your commitment to better health! Walking is ideal for weight management - it's gentle, effective, and enjoyable.",
                "You're making wonderful progress! Walking is perfect for your weight management goals - it's sustainable and feels great."
              ];
          return messages[dailySeed % messages.length];
        } else {
          final messages = [
            "Your commitment to walking shows real dedication to your health. Every step counts toward reaching your healthy weight goals.",
            "I admire your dedication to walking for your health. Each step you take is bringing you closer to your healthy weight goals.",
            "Your walking commitment is inspiring. Every step is a step toward better health and reaching your weight goals."
          ];
          return messages[dailySeed % messages.length];
        }
        
      case 'Obese':
        if (age < 40) {
          final messages = [
            "I admire your commitment to improving your health. Walking is an excellent starting point - it's low-impact and highly effective for weight management.",
            "Your dedication to improving your health is inspiring. Walking is perfect for starting your journey - it's gentle yet effective.",
            "I respect your commitment to better health. Walking is an ideal starting point - it's low-impact and great for weight management."
          ];
          return messages[dailySeed % messages.length];
        } else {
          final messages = [
            "Your dedication to walking is inspiring. Regular physical activity is key to managing weight and improving overall health at any age.",
            "I admire your walking commitment. Physical activity is crucial for weight management and health improvement at any age.",
            "Your dedication is truly inspiring. Regular walking is essential for weight management and overall health improvement."
          ];
          return messages[dailySeed % messages.length];
        }
        
      default:
        final messages = [
          "Keep up the great work with your daily walking routine!",
          "Continue with your excellent walking habits!",
          "Maintain your wonderful walking routine!"
        ];
        return messages[dailySeed % messages.length];
    }
  }
  
  static String _getProgressMessage(int progressPercentage, String bmiCategory, int dailySeed) {
    if (progressPercentage >= 100) {
      final messages = [
        "🎉 Amazing! You've exceeded your daily goal! This kind of consistency is exactly what your body needs.",
        "🎉 Outstanding! You've surpassed your daily goal! Your dedication is truly inspiring.",
        "🎉 Incredible! You've blown past your daily goal! This consistency will transform your health."
      ];
      return messages[dailySeed % messages.length];
    } else if (progressPercentage >= 75) {
      final messages = [
        "You're so close to your goal! Just a few more steps and you'll hit your target for today.",
        "Almost there! You're very close to reaching your daily goal. Keep going!",
        "You're nearly there! Just a little more effort and you'll achieve your goal for today."
      ];
      return messages[dailySeed % messages.length];
    } else if (progressPercentage >= 50) {
      final messages = [
        "Great progress! You're halfway to your daily goal. Keep pushing forward!",
        "Excellent work! You've reached the halfway point. Keep up the momentum!",
        "Fantastic progress! You're 50% there. You've got this!"
      ];
      return messages[dailySeed % messages.length];
    } else if (progressPercentage >= 25) {
      final messages = [
        "Good start! You've made solid progress toward your daily goal. Every step counts!",
        "Nice beginning! You're making good progress. Keep building on this momentum!",
        "Great start! You're on your way to your goal. Every step is progress!"
      ];
      return messages[dailySeed % messages.length];
    } else {
      final messages = [
        "It's early in the day - plenty of time to reach your goal! Start with a short walk and build from there.",
        "The day is young - lots of time to achieve your goal! Begin with a small walk and grow from there.",
        "Early in the day - perfect time to start working toward your goal! Take it step by step."
      ];
      return messages[dailySeed % messages.length];
    }
  }
  
  static String _getMotivationalMessage(String bmiCategory, int age, String gender, int dailySeed) {
    switch (bmiCategory) {
      case 'Underweight':
        final messages = [
          "💪 Remember: Healthy weight gain is a marathon, not a sprint. Focus on nutritious foods and consistent activity.",
          "💪 Patience is key: Healthy weight gain takes time. Stay consistent with your walking and nutrition.",
          "💪 Stay committed: Building healthy weight is a journey. Your daily walking is building a strong foundation."
        ];
        return messages[dailySeed % messages.length];
        
      case 'Normal weight':
        final messages = [
          "🌟 You're setting a great example! Maintaining healthy habits now pays off for years to come.",
          "🌟 You're an inspiration! Your healthy habits today are investments in your future health.",
          "🌟 Keep leading by example! Your consistent walking routine is building lasting health benefits."
        ];
        return messages[dailySeed % messages.length];
        
      case 'Overweight':
        final messages = [
          "🔥 Every step forward is progress. You're building sustainable habits that will last a lifetime.",
          "🔥 Each step counts: You're creating lasting change through your daily walking routine.",
          "🔥 Stay focused: Every walk is progress toward your health goals. You're building momentum!"
        ];
        return messages[dailySeed % messages.length];
        
      case 'Obese':
        final messages = [
          "💪 You're stronger than you think. Each day you choose to move is a victory for your health.",
          "💪 Your determination is inspiring. Every day you walk is a step toward better health.",
          "💪 Keep pushing forward: Each step you take is a victory. You're stronger than you realize."
        ];
        return messages[dailySeed % messages.length];
        
      default:
        final messages = [
          "Keep moving forward, one step at a time!",
          "Stay consistent with your walking routine!",
          "Every step brings you closer to your goals!"
        ];
        return messages[dailySeed % messages.length];
    }
  }
  
  static Future<String> getQuickTip(UserProfile profile) async {
    final bmiCategory = profile.bmiCategory;
    final age = profile.age;
    final dailySeed = await _getDailySeed();
    
    switch (bmiCategory) {
      case 'Underweight':
        if (age < 25) {
          final tips = [
            "💡 Tip: Try walking after meals to boost your appetite naturally!",
            "💡 Tip: Take a 15-minute walk before breakfast to stimulate your metabolism!",
            "💡 Tip: Walk with light weights to build muscle while getting your steps in!"
          ];
          return tips[dailySeed % tips.length];
        } else {
          final tips = [
            "💡 Tip: Morning walks can help kickstart your metabolism for the day!",
            "💡 Tip: Try walking in the evening to improve your sleep quality!",
            "💡 Tip: Include some uphill walking to build strength and appetite!"
          ];
          return tips[dailySeed % tips.length];
        }
          
      case 'Normal weight':
        if (age < 30) {
          final tips = [
            "💡 Tip: Mix up your walking routine with different speeds and inclines!",
            "💡 Tip: Try interval walking - alternate between fast and slow paces!",
            "💡 Tip: Explore new routes to keep your walks interesting and engaging!"
          ];
          return tips[dailySeed % tips.length];
        } else {
          final tips = [
            "💡 Tip: Walking with friends makes exercise more enjoyable and social!",
            "💡 Tip: Listen to podcasts or audiobooks during your walks!",
            "💡 Tip: Try walking in nature to reduce stress and boost mood!"
          ];
          return tips[dailySeed % tips.length];
        }
          
      case 'Overweight':
        final tips = [
          "💡 Tip: Start with shorter walks and gradually increase duration - consistency beats intensity!",
          "💡 Tip: Walk at a comfortable pace - you should be able to talk while walking!",
          "💡 Tip: Break your walks into smaller sessions throughout the day!"
        ];
        return tips[dailySeed % tips.length];
        
      case 'Obese':
        final tips = [
          "💡 Tip: Walking in water or on soft surfaces can be easier on your joints!",
          "💡 Tip: Use a walking stick or poles for extra support and stability!",
          "💡 Tip: Start with just 5-10 minutes and gradually build up your time!"
        ];
        return tips[dailySeed % tips.length];
        
      default:
        final tips = [
          "💡 Tip: Consistency is key - even 10 minutes of walking daily makes a difference!",
          "💡 Tip: Set small, achievable goals and celebrate each milestone!",
          "💡 Tip: Track your progress to stay motivated and see your improvements!"
        ];
        return tips[dailySeed % tips.length];
    }
  }
  
  static String getGoalSuggestion(UserProfile profile) {
    final bmiCategory = profile.bmiCategory;
    final currentGoal = profile.dailyStepGoal;
    
    switch (bmiCategory) {
      case 'Underweight':
        if (currentGoal < 8000) {
          return "Consider increasing your goal to 8,000-10,000 steps to support healthy weight gain.";
        }
        break;
        
      case 'Normal weight':
        if (currentGoal < 10000) {
          return "You might benefit from a 10,000-12,000 step goal for optimal health maintenance.";
        }
        break;
        
      case 'Overweight':
        if (currentGoal < 8000) {
          return "Aim for 8,000-10,000 steps daily for effective weight management.";
        }
        break;
        
      case 'Obese':
        if (currentGoal < 6000) {
          return "Start with 6,000-8,000 steps and gradually increase as you build endurance.";
        }
        break;
    }
    
    return "Your current goal looks great for your profile!";
  }
}
