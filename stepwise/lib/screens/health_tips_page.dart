import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Responsive helper
class Responsive {
  static double font(BuildContext context, double size) {
    double baseWidth = 375.0; // iPhone 11 Pro width
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
  static double pad(BuildContext context, double value) {
    double baseWidth = 375.0;
    double screenWidth = MediaQuery.of(context).size.width;
    return value * (screenWidth / baseWidth);
  }
}

class HealthTip {
  final String title;
  final String summary;
  final String fullContent;
  final String category;
  final IconData icon;
  final List<String>? benefits;
  final List<String>? tips;

  HealthTip({
    required this.title,
    required this.summary,
    required this.fullContent,
    required this.category,
    required this.icon,
    this.benefits,
    this.tips,
  });
}

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});

  @override
  HealthTipsPageState createState() => HealthTipsPageState();
}

class HealthTipsPageState extends State<HealthTipsPage> {
  final List<HealthTip> _healthTips = [
    HealthTip(
        title: 'Stay Hydrated',
        summary: 'Drinking enough water daily is crucial for many reasons: to regulate body temperature, keep joints lubricated, prevent infections, deliver nutrients to cells, and keep organs functioning properly.',
      fullContent: '''Water is essential for life and plays a crucial role in maintaining good health. Your body is made up of about 60% water, and every system depends on it to function properly.

**Why Hydration Matters:**
• Regulates body temperature through sweating and respiration
• Lubricates joints and cushions organs
• Transports nutrients and oxygen to cells
• Flushes out waste products and toxins
• Maintains blood pressure and circulation
• Supports digestion and nutrient absorption

**How Much Water Do You Need?**
The general recommendation is 8 glasses (64 ounces) per day, but individual needs vary based on:
• Body size and weight
• Activity level and exercise intensity
• Climate and weather conditions
• Diet (high-sodium foods require more water)
• Pregnancy or breastfeeding status

**Signs of Dehydration:**
• Thirst and dry mouth
• Dark yellow urine
• Fatigue and dizziness
• Headaches
• Dry skin
• Muscle cramps

**Tips for Staying Hydrated:**
• Carry a reusable water bottle
• Set reminders on your phone
• Drink water before, during, and after exercise
• Eat water-rich foods like fruits and vegetables
• Monitor your urine color (aim for light yellow)
• Drink water with meals''',
        category: 'Nutrition',
      icon: Icons.water_drop,
      benefits: [
        'Improved physical performance',
        'Better cognitive function',
        'Enhanced skin health',
        'Reduced risk of kidney stones',
        'Better digestion',
        'Increased energy levels'
      ],
      tips: [
        'Start your day with a glass of water',
        'Keep a water bottle at your desk',
        'Add lemon or cucumber for flavor',
        'Drink water before meals',
        'Set hourly hydration reminders'
      ],
    ),
    HealthTip(
        title: 'The 20-20-20 Rule',
        summary: 'To prevent eye strain, look away from your screen every 20 minutes and focus on an object 20 feet away for at least 20 seconds.',
      fullContent: '''Digital eye strain, also known as computer vision syndrome, affects millions of people who spend long hours looking at screens. The 20-20-20 rule is a simple but effective technique to reduce eye strain and prevent long-term vision problems.

**What is Digital Eye Strain?**
Digital eye strain occurs when your eyes work harder than usual to focus on digital screens. Common symptoms include:
• Dry, irritated eyes
• Blurred vision
• Headaches
• Neck and shoulder pain
• Difficulty focusing
• Eye fatigue

**How the 20-20-20 Rule Works:**
Every 20 minutes, take a 20-second break and look at something 20 feet away. This gives your eye muscles a chance to relax and refocus, reducing strain and fatigue.

**Why This Works:**
• **Reduces focusing fatigue**: Your eyes constantly adjust focus when looking at screens
• **Prevents dry eyes**: Blinking less while staring at screens dries out your eyes
• **Relieves muscle tension**: Eye muscles get tired from prolonged close-up work
• **Improves circulation**: Brief breaks improve blood flow to the eyes

**Additional Eye Care Tips:**
• Position your screen 20-28 inches from your eyes
• Keep the top of your screen at or slightly below eye level
• Reduce screen brightness to match your surroundings
• Use blue light filters or glasses
• Ensure proper lighting in your workspace
• Take regular breaks every hour

**Ergonomic Setup:**
• Adjust your chair height so your feet rest flat on the floor
• Keep your wrists straight and elbows at 90 degrees
• Position your monitor to avoid glare from windows or lights
• Use an external keyboard and mouse for laptops

**When to See an Eye Doctor:**
• Persistent eye strain despite following the 20-20-20 rule
• Frequent headaches or migraines
• Blurred vision that doesn't improve with breaks
• Dry eyes that don't respond to artificial tears
• Changes in vision or eye discomfort''',
        category: 'Wellness',
      icon: Icons.visibility,
      benefits: [
        'Reduced eye strain and fatigue',
        'Prevention of digital eye strain',
        'Better focus and productivity',
        'Reduced headaches',
        'Improved long-term eye health',
        'Better sleep quality'
      ],
      tips: [
        'Set a timer for 20-minute intervals',
        'Use apps that remind you to take breaks',
        'Practice the rule during all screen time',
        'Combine with stretching exercises',
        'Use artificial tears if needed'
      ],
    ),
    HealthTip(
        title: 'Incorporate Strength Training',
        summary: 'Aim for at least two strength training sessions per week. This can help build muscle mass, improve bone density, and boost your metabolism.',
      fullContent: '''Strength training, also known as resistance training, is a form of exercise that uses resistance to build muscle strength, endurance, and size. It's essential for overall health and should be part of everyone's fitness routine, regardless of age or fitness level.

**Benefits of Strength Training:**
• **Increased muscle mass**: Builds and maintains lean muscle tissue
• **Improved bone density**: Reduces risk of osteoporosis and fractures
• **Enhanced metabolism**: Muscle tissue burns more calories at rest
• **Better posture**: Strengthens core and supporting muscles
• **Reduced injury risk**: Stronger muscles protect joints and bones
• **Improved mental health**: Releases endorphins and reduces stress
• **Better balance**: Enhances stability and coordination
• **Increased functional strength**: Makes daily activities easier

**Getting Started:**
**Frequency**: Aim for 2-3 sessions per week with at least one day of rest between sessions
**Duration**: 20-60 minutes per session
**Intensity**: Start with lighter weights and focus on proper form

**Basic Strength Training Program:**
**Upper Body:**
• Push-ups or chest press
• Rows or pull-ups
• Shoulder press
• Bicep curls
• Tricep dips

**Lower Body:**
• Squats
• Lunges
• Deadlifts
• Calf raises
• Step-ups

**Core:**
• Planks
• Crunches
• Russian twists
• Bird dogs
• Dead bugs

**Progressive Overload:**
Gradually increase the challenge by:
• Adding more weight
• Increasing repetitions
• Adding more sets
• Reducing rest time
• Improving exercise form

**Safety Tips:**
• Warm up with 5-10 minutes of cardio
• Start with bodyweight exercises
• Focus on proper form over weight
• Breathe steadily throughout exercises
• Listen to your body and rest when needed
• Stay hydrated during workouts

**When to Progress:**
• When you can complete all sets with good form
• When exercises feel too easy
• After 2-4 weeks of consistent training
• When you're ready for more challenge

**Equipment Options:**
• Bodyweight exercises (no equipment needed)
• Resistance bands
• Dumbbells
• Barbells
• Machines at the gym
• Household items (water bottles, books)

**Recovery and Nutrition:**
• Allow 48-72 hours between training the same muscle groups
• Consume adequate protein (0.8-1.2g per kg body weight)
• Stay hydrated before, during, and after workouts
• Get 7-9 hours of quality sleep
• Consider protein timing around workouts''',
        category: 'Exercise',
      icon: Icons.fitness_center,
      benefits: [
        'Increased muscle strength and mass',
        'Improved bone density',
        'Enhanced metabolism',
        'Better posture and balance',
        'Reduced injury risk',
        'Improved mental health'
      ],
      tips: [
        'Start with bodyweight exercises',
        'Focus on proper form first',
        'Gradually increase intensity',
        'Include all major muscle groups',
        'Allow adequate recovery time'
      ],
    ),
    HealthTip(
        title: 'Eat a Balanced Diet',
        summary: 'Include a variety of fruits, vegetables, lean proteins, and whole grains in your diet. A balanced diet provides the essential nutrients your body needs to function effectively.',
      fullContent: '''A balanced diet provides your body with the essential nutrients it needs to function optimally. It's not about strict limitations or depriving yourself, but rather about creating a sustainable eating pattern that nourishes your body and supports your health goals.

**What is a Balanced Diet?**
A balanced diet includes a variety of foods from all major food groups in appropriate proportions:
• **Fruits and Vegetables**: 50% of your plate
• **Whole Grains**: 25% of your plate
• **Lean Proteins**: 25% of your plate
• **Healthy Fats**: Small amounts throughout the day
• **Dairy or Alternatives**: 2-3 servings daily

**Key Components:**

**1. Fruits and Vegetables (5-9 servings daily)**
• Rich in vitamins, minerals, and antioxidants
• High in fiber for digestive health
• Low in calories and fat
• Help reduce risk of chronic diseases

**2. Whole Grains (6-8 servings daily)**
• Provide complex carbohydrates for energy
• Rich in fiber, B vitamins, and minerals
• Help maintain stable blood sugar levels
• Support digestive health

**3. Lean Proteins (2-3 servings daily)**
• Essential for building and repairing tissues
• Important for immune function
• Helps maintain muscle mass
• Provides satiety and helps control hunger

**4. Healthy Fats (20-35% of daily calories)**
• Essential for hormone production
• Helps absorb fat-soluble vitamins
• Provides long-lasting energy
• Supports brain health

**5. Dairy and Alternatives (2-3 servings daily)**
• Excellent source of calcium and vitamin D
• Important for bone health
• Provides protein and other nutrients
• Choose low-fat or non-fat options

**Meal Planning Tips:**
• **Plan ahead**: Prepare meals and snacks in advance
• **Shop smart**: Make a grocery list and stick to it
• **Cook at home**: You control ingredients and portions
• **Use the plate method**: Fill half with vegetables, quarter with protein, quarter with grains
• **Practice portion control**: Use smaller plates and bowls
• **Eat mindfully**: Pay attention to hunger and fullness cues

**Healthy Eating Habits:**
• Eat breakfast to jumpstart your metabolism
• Include protein with every meal
• Choose whole foods over processed foods
• Limit added sugars and sodium
• Stay hydrated throughout the day
• Practice portion control
• Eat slowly and savor your food
• Listen to your body's hunger signals

**Common Myths Debunked:**
• **Myth**: Carbs are bad for you
• **Fact**: Complex carbohydrates are essential for energy and health

• **Myth**: Fat makes you fat
• **Fact**: Healthy fats are essential and can help with weight management

• **Myth**: You need to eat every 2-3 hours
• **Fact**: Listen to your body's hunger cues

• **Myth**: All calories are equal
• **Fact**: Nutrient quality matters more than calorie counting

**Special Considerations:**
• **Vegetarian/Vegan**: Ensure adequate protein and B12 intake
• **Gluten-free**: Choose naturally gluten-free whole grains
• **Food allergies**: Work with a dietitian to ensure balanced nutrition
• **Medical conditions**: Consult healthcare providers for specific dietary needs

**Making Sustainable Changes:**
• Start with small, manageable changes
• Focus on adding healthy foods rather than restricting
• Be patient with yourself and your progress
• Celebrate small victories along the way
• Remember that perfection is not the goal''',
        category: 'Nutrition',
      icon: Icons.restaurant,
      benefits: [
        'Improved energy levels',
        'Better digestive health',
        'Enhanced immune function',
        'Reduced risk of chronic diseases',
        'Better mood and mental health',
        'Healthy weight management'
      ],
      tips: [
        'Use the plate method for portion control',
        'Include protein with every meal',
        'Choose whole foods over processed',
        'Plan meals and snacks ahead',
        'Practice mindful eating'
      ],
    ),
    HealthTip(
        title: 'Prioritize Quality Sleep',
        summary: 'Aim for 7-9 hours of quality sleep per night. Good sleep improves brain function, mood, and overall health. Establish a regular sleep schedule and create a restful environment.',
      fullContent: '''Sleep is not just a period of rest—it's a critical biological process that affects every aspect of your health and well-being. Quality sleep is essential for physical recovery, mental clarity, emotional regulation, and overall health.

**Why Sleep Matters:**
• **Physical Recovery**: Muscles repair and grow during sleep
• **Brain Function**: Memory consolidation and learning occur during sleep
• **Immune Function**: Sleep strengthens your immune system
• **Hormone Regulation**: Sleep affects hunger, stress, and growth hormones
• **Emotional Health**: Sleep helps regulate mood and emotional responses
• **Cardiovascular Health**: Sleep affects blood pressure and heart health

**Sleep Cycles and Stages:**
Sleep consists of several cycles, each lasting about 90 minutes:

**Stage 1 (Light Sleep)**: 5-10 minutes
• Transition from wakefulness to sleep
• Easy to wake up
• Body begins to relax

**Stage 2 (Light Sleep)**: 20-30 minutes
• Heart rate and breathing slow
• Body temperature drops
• Brain waves slow down

**Stage 3 (Deep Sleep)**: 20-40 minutes
• Physical restoration occurs
• Immune system strengthens
• Difficult to wake up

**REM Sleep**: 10-60 minutes
• Brain activity increases
• Dreams occur
• Memory consolidation
• Emotional processing

**How Much Sleep Do You Need?**
• **Adults (18-64)**: 7-9 hours per night
• **Older Adults (65+)**: 7-8 hours per night
• **Teenagers (14-17)**: 8-10 hours per night
• **Children (6-13)**: 9-11 hours per night

**Signs of Poor Sleep Quality:**
• Difficulty falling or staying asleep
• Waking up feeling unrefreshed
• Daytime fatigue and sleepiness
• Difficulty concentrating
• Mood changes and irritability
• Increased appetite and weight gain
• Weakened immune system

**Creating a Sleep-Friendly Environment:**

**Bedroom Setup:**
• Keep room cool (65-68°F/18-20°C)
• Ensure darkness with blackout curtains
• Reduce noise with earplugs or white noise
• Choose a comfortable mattress and pillows
• Keep electronics out of the bedroom

**Sleep Hygiene Practices:**
• **Consistent Schedule**: Go to bed and wake up at the same time daily
• **Bedtime Routine**: Create a relaxing pre-sleep ritual
• **Limit Caffeine**: Avoid caffeine after 2 PM
• **Avoid Alcohol**: Can disrupt sleep quality
• **Exercise**: Regular exercise improves sleep, but avoid intense workouts close to bedtime
• **Screen Time**: Avoid screens 1-2 hours before bed
• **Meal Timing**: Avoid large meals close to bedtime

**Bedtime Routine Ideas:**
• Take a warm bath or shower
• Read a book (not on a screen)
• Practice relaxation techniques
• Listen to calming music
• Write in a journal
• Practice gentle stretching
• Use aromatherapy (lavender)

**Managing Sleep Problems:**

**Insomnia:**
• Practice good sleep hygiene
• Try relaxation techniques
• Consider cognitive behavioral therapy
• Avoid sleeping pills unless prescribed

**Sleep Apnea:**
• Consult a healthcare provider
• Consider a sleep study
• Maintain a healthy weight
• Sleep on your side

**Restless Legs Syndrome:**
• Exercise regularly
• Avoid caffeine and alcohol
• Try stretching before bed
• Consider iron supplements if deficient

**When to Seek Help:**
• Persistent difficulty falling or staying asleep
• Excessive daytime sleepiness
• Loud snoring or breathing pauses
• Unusual movements during sleep
• Sleep problems affecting daily life
• Sleep problems lasting more than a few weeks

**Sleep and Technology:**
• Use sleep tracking apps to monitor patterns
• Consider smart devices that optimize sleep environment
• Use blue light filters on devices
• Set up "Do Not Disturb" modes

**Sleep Myths:**
• **Myth**: You can catch up on sleep on weekends
• **Fact**: Sleep debt can't be fully repaid

• **Myth**: Older adults need less sleep
• **Fact**: Sleep needs remain similar throughout adulthood

• **Myth**: Snoring is harmless
• **Fact**: Snoring can indicate sleep apnea

• **Myth**: Alcohol helps you sleep better
• **Fact**: Alcohol disrupts sleep quality''',
        category: 'Wellness',
      icon: Icons.nights_stay,
      benefits: [
        'Improved memory and learning',
        'Enhanced immune function',
        'Better mood and emotional regulation',
        'Reduced risk of chronic diseases',
        'Improved physical performance',
        'Better stress management'
      ],
      tips: [
        'Maintain a consistent sleep schedule',
        'Create a relaxing bedtime routine',
        'Keep your bedroom cool and dark',
        'Avoid screens before bedtime',
        'Exercise regularly but not close to bedtime'
      ],
    ),
    HealthTip(
        title: 'Practice Mindful Stretching',
        summary: 'Incorporate regular stretching into your routine to improve flexibility, reduce muscle tension, and increase blood flow. Even a few minutes a day can make a difference.',
      fullContent: '''Mindful stretching combines the physical benefits of stretching with the mental benefits of mindfulness. It's a gentle, accessible form of exercise that can improve flexibility, reduce stress, and enhance overall well-being.

**What is Mindful Stretching?**
Mindful stretching involves paying full attention to your body and breath while performing gentle stretches. It's not about pushing your limits or achieving extreme flexibility, but rather about connecting with your body and creating awareness.

**Benefits of Mindful Stretching:**
• **Improved Flexibility**: Increases range of motion in joints
• **Reduced Muscle Tension**: Releases tight muscles and knots
• **Better Posture**: Strengthens core and supporting muscles
• **Stress Relief**: Activates the relaxation response
• **Enhanced Body Awareness**: Improves proprioception
• **Better Circulation**: Increases blood flow to muscles
• **Pain Relief**: Can reduce chronic pain and discomfort
• **Mental Clarity**: Calms the mind and improves focus

**Types of Stretching:**

**1. Static Stretching**
• Hold a stretch for 15-60 seconds
• Best for improving flexibility
• Perform after exercise or when muscles are warm
• Examples: hamstring stretch, quad stretch, shoulder stretch

**2. Dynamic Stretching**
• Move through a range of motion
• Best for warming up before exercise
• Improves mobility and prepares muscles
• Examples: arm circles, leg swings, hip circles

**3. PNF Stretching (Proprioceptive Neuromuscular Facilitation)**
• Combines stretching with muscle contraction
• Most effective for increasing flexibility
• Requires a partner or equipment
• Advanced technique

**Mindful Stretching Routine:**

**Morning Routine (5-10 minutes):**
1. **Cat-Cow Stretch**: On hands and knees, alternate arching and rounding your back
2. **Child's Pose**: Kneel and reach forward, stretching your back and shoulders
3. **Standing Forward Fold**: Bend forward from hips, letting head and arms hang
4. **Gentle Twists**: Seated or standing, rotate torso slowly
5. **Ankle and Wrist Circles**: Improve joint mobility

**Evening Routine (10-15 minutes):**
1. **Seated Forward Bend**: Stretch hamstrings and lower back
2. **Butterfly Stretch**: Open hips and stretch inner thighs
3. **Cobra Pose**: Strengthen back and open chest
4. **Pigeon Pose**: Stretch hip flexors and glutes
5. **Legs Up the Wall**: Relax and improve circulation

**Mindfulness Techniques:**
• **Breath Awareness**: Focus on your breath during stretches
• **Body Scanning**: Notice sensations in different parts of your body
• **Present Moment**: Stay focused on the current stretch
• **Non-Judgment**: Accept your current flexibility level
• **Gratitude**: Appreciate your body's capabilities

**Safety Guidelines:**
• **Warm Up**: Light movement before stretching
• **Go Slow**: Ease into stretches gradually
• **Listen to Your Body**: Stop if you feel pain
• **Breathe**: Maintain steady breathing throughout
• **Don't Bounce**: Avoid ballistic stretching
• **Hold Stretches**: 15-60 seconds for static stretches
• **Be Consistent**: Regular practice yields better results

**Stretching for Specific Areas:**

**Neck and Shoulders:**
• Neck rolls and tilts
• Shoulder shrugs and rolls
• Doorway chest stretch
• Upper trapezius stretch

**Back and Core:**
• Cat-cow stretch
• Child's pose
• Cobra pose
• Gentle twists

**Hips and Legs:**
• Hip flexor stretch
• Hamstring stretch
• Quad stretch
• Butterfly stretch
• Pigeon pose

**Arms and Wrists:**
• Tricep stretch
• Bicep stretch
• Wrist flexor and extensor stretches
• Finger stretches

**When to Stretch:**
• **Morning**: Light stretching to wake up your body
• **Before Exercise**: Dynamic stretching to warm up
• **After Exercise**: Static stretching to cool down
• **Evening**: Gentle stretching to relax before bed
• **Throughout the Day**: Quick stretches during breaks

**Common Mistakes to Avoid:**
• Stretching cold muscles
• Bouncing or jerking movements
• Holding breath during stretches
• Pushing beyond comfortable limits
• Rushing through stretches
• Ignoring pain signals

**Progress and Consistency:**
• Start with 5-10 minutes daily
• Gradually increase duration and intensity
• Be patient with your progress
• Celebrate small improvements
• Make stretching a habit

**Mindful Stretching for Stress Relief:**
• Focus on your breath
• Release tension with each exhale
• Visualize stress leaving your body
• Practice gratitude for your body
• Use stretching as a meditation tool

**Equipment and Props:**
• Yoga mat for comfort
• Stretching straps for assistance
• Foam roller for self-massage
• Blocks for support
• Bolsters for relaxation

**When to Seek Professional Help:**
• Persistent pain during stretching
• Limited range of motion
• Previous injuries affecting movement
• Chronic pain conditions
• Need for personalized guidance''',
        category: 'Exercise',
      icon: Icons.self_improvement,
      benefits: [
        'Improved flexibility and range of motion',
        'Reduced muscle tension and stress',
        'Better posture and alignment',
        'Enhanced body awareness',
        'Improved circulation',
        'Better mental clarity and focus'
      ],
      tips: [
        'Start with gentle stretches',
        'Focus on your breath',
        'Hold stretches for 15-60 seconds',
        'Listen to your body',
        'Make stretching a daily habit'
      ],
    ),
  ];

  Map<String, List<HealthTip>> get _categorizedTips {
    final map = <String, List<HealthTip>>{};
    for (var tip in _healthTips) {
      (map[tip.category] ??= []).add(tip);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final categories = _categorizedTips;
    final categoryKeys = categories.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Health & Wellness Tips', style: AppTextStyles.title(brightness)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categoryKeys.length,
        itemBuilder: (context, index) {
          final category = categoryKeys[index];
          final tips = categories[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Text(
                  category,
                  style: AppTextStyles.heading(brightness).copyWith(fontSize: 22),
                ),
              ),
              ...tips.map((tip) => _buildTipCard(tip, brightness)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipCard(HealthTip tip, Brightness brightness) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: AppColors.getSecondary(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getBorder(brightness), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tip.icon, color: AppColors.getPrimary(brightness), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tip.title, style: AppTextStyles.bodyBold(brightness)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(tip.summary, style: AppTextStyles.body(brightness)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthTipDetailPage(tip: tip),
                    ),
                  );
                },
                child: Text(
                  'Read More',
                  style: AppTextStyles.button(brightness).copyWith(color: AppColors.getPrimary(brightness)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthTipDetailPage extends StatelessWidget {
  final HealthTip tip;

  const HealthTipDetailPage({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final double hPad = Responsive.pad(context, 16);
    final double vPad = Responsive.pad(context, 16);
    final double headingSize = Responsive.font(context, 22);
    final double titleSize = Responsive.font(context, 18);
    final double bodySize = Responsive.font(context, 15);
    final double subtitleSize = Responsive.font(context, 16);
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text(tip.title, style: AppTextStyles.title(brightness).copyWith(fontSize: headingSize)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getPrimary(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and category
            Card(
              color: AppColors.getSecondary(brightness),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(Responsive.pad(context, 20)),
                child: Row(
                  children: [
                    Icon(tip.icon, color: AppColors.getPrimary(brightness), size: Responsive.font(context, 40)),
                    SizedBox(width: Responsive.pad(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: AppTextStyles.heading(brightness).copyWith(fontSize: titleSize)),
                          SizedBox(height: Responsive.pad(context, 4)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.pad(context, 12), vertical: Responsive.pad(context, 6)),
                            decoration: BoxDecoration(
                              color: AppColors.getPrimary(brightness).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tip.category,
                              style: AppTextStyles.body(brightness).copyWith(
                                color: AppColors.getPrimary(brightness),
                                fontWeight: FontWeight.w600,
                                fontSize: bodySize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Responsive.pad(context, 24)),
            
            // Full content
            Text(
              'Complete Guide',
              style: AppTextStyles.subtitle(brightness).copyWith(fontWeight: FontWeight.bold, fontSize: subtitleSize),
            ),
            SizedBox(height: Responsive.pad(context, 12)),
            MarkdownBody(
              data: tip.fullContent,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: AppTextStyles.body(brightness).copyWith(height: 1.6, fontSize: bodySize),
                strong: AppTextStyles.body(brightness).copyWith(fontWeight: FontWeight.bold, fontSize: bodySize),
              ),
            ),
            
            // Benefits section
            if (tip.benefits != null && tip.benefits!.isNotEmpty) ...[
              SizedBox(height: Responsive.pad(context, 32)),
              Text(
                'Key Benefits',
                style: AppTextStyles.subtitle(brightness).copyWith(fontWeight: FontWeight.bold, fontSize: subtitleSize),
              ),
              SizedBox(height: Responsive.pad(context, 12)),
              ...tip.benefits!.map((benefit) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.pad(context, 8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: Responsive.font(context, 20),
                    ),
                    SizedBox(width: Responsive.pad(context, 12)),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTextStyles.body(brightness).copyWith(fontSize: bodySize),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            // Tips section
            if (tip.tips != null && tip.tips!.isNotEmpty) ...[
              SizedBox(height: Responsive.pad(context, 32)),
              Text(
                'Practical Tips',
                style: AppTextStyles.subtitle(brightness).copyWith(fontWeight: FontWeight.bold, fontSize: subtitleSize),
              ),
              SizedBox(height: Responsive.pad(context, 12)),
              ...tip.tips!.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.pad(context, 12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: Responsive.font(context, 24),
                      height: Responsive.font(context, 24),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(brightness),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.font(context, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.pad(context, 12)),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTextStyles.body(brightness).copyWith(fontSize: bodySize),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            SizedBox(height: Responsive.pad(context, 32)),
          ],
        ),
      ),
    );
  }
} 