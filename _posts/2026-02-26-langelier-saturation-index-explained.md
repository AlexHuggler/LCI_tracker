---
layout: post
title: "The Langelier Saturation Index (LSI) Explained: A Pool Tech's Guide"
date: 2026-02-26
categories: [water-chemistry]
tags: [lsi, water-chemistry, langelier, calcium, alkalinity, pool-balance]
description: "Master the Langelier Saturation Index formula, CYA correction, and practical LSI calculations to keep every pool perfectly balanced."
author: "PoolFlow Team"
image: /assets/images/og-image.png
executive_summary: |
  The Langelier Saturation Index (LSI) is the definitive measure of water balance in swimming pools, determining whether water is corrosive, balanced, or scale-forming. This flagship technical guide breaks down the complete LSI formula: LSI equals pH plus Temperature Factor plus Calcium Factor plus Alkalinity Factor minus TDS Constant. Each factor is explained in detail with lookup tables and practical context. The critical CYA correction, where adjusted alkalinity equals total alkalinity minus cyanuric acid divided by three, is thoroughly examined because ignoring it leads to inaccurate LSI readings in stabilized pools. The guide provides multiple worked examples with real numbers, explains the consequences of operating outside the balanced range, and gives specific correction strategies using industry-standard dosing rates. This is essential knowledge for every pool service professional who wants to move beyond guesswork to scientifically precise water management.
faq:
  - question: "What is a good LSI for a pool?"
    answer: "A good LSI for a swimming pool falls within the balanced range of -0.3 to +0.3. An LSI of exactly 0.0 represents perfectly balanced water that is neither corrosive nor scale-forming. In practice, maintaining the LSI between -0.2 and +0.2 provides an ideal target with a comfortable margin. Slightly positive values (up to +0.3) are generally preferable to slightly negative values because mild scale tendency is less destructive than mild corrosive tendency, particularly for plaster and marcite pool surfaces."
  - question: "Why does CYA affect the LSI calculation?"
    answer: "Cyanuric acid (CYA) affects the LSI calculation because it binds with a portion of the carbonate alkalinity in pool water, effectively reducing the alkalinity that is available to buffer pH and participate in calcium carbonate saturation chemistry. Approximately one-third of the CYA concentration sequesters carbonate alkalinity, which is why the CYA correction formula is adjusted alkalinity equals total alkalinity minus CYA divided by three. Without this correction, the LSI calculation in a stabilized pool will overestimate the water's alkalinity contribution and produce a falsely high LSI reading, potentially masking corrosive conditions."
  - question: "How often should I calculate LSI?"
    answer: "Pool service professionals should calculate the LSI at every service visit, which is typically weekly for residential pools and at least twice daily for commercial pools. The LSI should also be recalculated whenever any contributing parameter changes significantly, such as after chemical adjustments, fresh water additions, heavy rain events, or temperature swings. Seasonal transitions are particularly important because temperature changes directly affect the LSI through the Temperature Factor, meaning water that was balanced in summer may become corrosive in winter without any change in chemical parameters."
---

## Introduction: The Science of Water Balance

Every swimming pool is engaged in an invisible chemical struggle. The water is constantly seeking equilibrium with calcium carbonate, the mineral compound that forms the basis of plaster, marcite, and pebble pool surfaces. When the water is undersaturated with calcium carbonate, it becomes aggressive, dissolving calcium from pool surfaces, etching plaster, corroding metal components, and degrading equipment. When the water is oversaturated, calcium carbonate precipitates out of solution, forming scale deposits on surfaces, inside pipes, and on heat exchangers.

The Langelier Saturation Index, developed by Dr. Wilfred Langelier in 1936, provides a single numerical value that tells you exactly where your pool water stands in this equilibrium. It is not an approximation or a rule of thumb. It is a scientifically derived calculation that predicts the water's tendency to dissolve or deposit calcium carbonate.

For pool service professionals, the LSI is the most important number you can calculate. It integrates five water chemistry parameters into a single actionable value that determines whether your water is protecting the pool or destroying it. Mastering the LSI separates competent technicians from true water chemistry professionals.

## The Complete LSI Formula

The Langelier Saturation Index is calculated as follows:

**LSI = pH + TF + CF + AF - TDS Constant**

Where:

- **pH** = the measured pH of the pool water
- **TF** = Temperature Factor (derived from water temperature)
- **CF** = Calcium Factor (derived from calcium hardness concentration)
- **AF** = Alkalinity Factor (derived from total alkalinity, with CYA correction)
- **TDS Constant** = a constant derived from Total Dissolved Solids

Each of these components contributes to the overall saturation state of the water. Let us examine each factor in detail.

## pH: The Direct Input

pH is the only component of the LSI formula that enters directly as a measured value without conversion to a factor. The pH of pool water measures the concentration of hydrogen ions on a logarithmic scale from 0 to 14, where 7.0 is neutral, values below 7.0 are acidic, and values above 7.0 are basic (alkaline).

For swimming pools, the acceptable pH range is 7.2 to 7.8, with 7.4 to 7.6 considered ideal. pH has the most immediate and direct impact on the LSI value. Because it enters the formula without transformation, every 0.1 change in pH produces exactly a 0.1 change in the LSI.

This direct relationship means pH is both the parameter most likely to push the LSI out of range and the easiest parameter to adjust for quick LSI correction. However, adjusting pH without considering its effect on the other parameters, particularly alkalinity, can create a cycle of constant adjustment that never achieves true balance.

For a comprehensive discussion of pH management and its relationship to other water chemistry parameters, see our [complete water balance and chemistry guide](/blog/pool-water-balance-chemistry-guide/).

## Temperature Factor (TF)

Water temperature affects the solubility of calcium carbonate. Warmer water holds less calcium carbonate in solution, meaning it has a greater tendency to deposit scale. Colder water holds more calcium carbonate, meaning it has a greater tendency to dissolve calcium from surfaces.

The Temperature Factor converts the water temperature into a value used in the LSI formula. The following table provides TF values for common pool water temperatures:

| Water Temperature (F) | Temperature Factor (TF) |
|----------------------|------------------------|
| 32                   | 0.0                    |
| 37                   | 0.1                    |
| 46                   | 0.2                    |
| 53                   | 0.3                    |
| 60                   | 0.4                    |
| 66                   | 0.5                    |
| 76                   | 0.6                    |
| 84                   | 0.7                    |
| 94                   | 0.8                    |
| 105                  | 0.9                    |

The Temperature Factor is a critical consideration for seasonal pool management. A pool that is perfectly balanced at 84 degrees Fahrenheit in summer (TF = 0.7) will see its LSI drop by 0.3 if the water temperature falls to 53 degrees Fahrenheit (TF = 0.3) in winter, with no other parameter changes. This shift alone can push balanced water into the corrosive range.

This is why pools in cooler climates or unheated pools during shoulder seasons often develop etching and corrosion problems. The temperature drop lowers the LSI, and if the other parameters are not adjusted to compensate, the water becomes aggressive toward pool surfaces and equipment.

## Calcium Factor (CF)

The Calcium Factor is derived from the calcium hardness concentration in the water, measured in parts per million (ppm). Calcium hardness represents the concentration of dissolved calcium ions, which are the key participants in the calcium carbonate saturation chemistry that the LSI models.

The Calcium Factor is calculated as the base-10 logarithm of the calcium hardness concentration minus 0.4. In practice, most technicians use a lookup table:

| Calcium Hardness (ppm) | Calcium Factor (CF) |
|------------------------|---------------------|
| 25                     | 1.0                 |
| 50                     | 1.3                 |
| 75                     | 1.5                 |
| 100                    | 1.6                 |
| 150                    | 1.8                 |
| 200                    | 1.9                 |
| 250                    | 2.0                 |
| 300                    | 2.1                 |
| 400                    | 2.2                 |
| 500                    | 2.3                 |
| 800                    | 2.5                 |
| 1000                   | 2.6                 |

The ideal calcium hardness range for pool water is 200 to 400 ppm. At 200 ppm, the Calcium Factor is 1.9; at 400 ppm, it is 2.2. This 0.3 difference in CF between the low and high ends of the ideal range directly translates to a 0.3 difference in the LSI.

Calcium hardness is the most difficult parameter to lower once it is elevated. While calcium can be added using calcium chloride at a rate of 20 ounces per 10,000 gallons to raise calcium by 10 ppm, the only practical way to reduce calcium is through dilution, partial drain and refill, or reverse osmosis treatment. This makes it essential to manage calcium proactively rather than reactively.

## Alkalinity Factor (AF) and the Critical CYA Correction

The Alkalinity Factor is derived from the total alkalinity of the pool water. However, in pools treated with cyanuric acid (CYA), which includes the vast majority of outdoor pools, a critical correction must be applied before calculating the AF.

### Why CYA Correction Is Essential

Cyanuric acid, commonly known as stabilizer or conditioner, protects chlorine from ultraviolet degradation. It is present in all pools that use stabilized chlorine products (trichlor and dichlor) and in pools where granular CYA has been added directly. Typical CYA levels in residential pools range from 30 to 50 ppm, though levels can climb much higher in pools that have not been partially drained.

CYA interacts with the carbonate alkalinity system in pool water. Approximately one-third of the CYA concentration effectively sequesters carbonate alkalinity, removing it from participation in the calcium carbonate equilibrium. If you use the raw total alkalinity reading in the LSI formula without accounting for this CYA effect, the calculation will overstate the water's alkalinity contribution and produce an LSI value that is falsely high.

This means a pool that appears balanced by a non-corrected LSI calculation may actually be corrosive. Technicians who ignore the CYA correction are flying blind and may be unknowingly allowing water to damage pool surfaces and equipment.

### The CYA Correction Formula

The correction is straightforward:

**Adjusted Alkalinity = Total Alkalinity - (CYA / 3)**

For example, if total alkalinity is 100 ppm and CYA is 60 ppm:

Adjusted Alkalinity = 100 - (60 / 3) = 100 - 20 = 80 ppm

The adjusted alkalinity value, not the raw total alkalinity, is then used to determine the Alkalinity Factor from the lookup table:

| Adjusted Alkalinity (ppm) | Alkalinity Factor (AF) |
|--------------------------|----------------------|
| 25                       | 1.4                  |
| 50                       | 1.7                  |
| 75                       | 1.9                  |
| 80                       | 1.9                  |
| 100                      | 2.0                  |
| 120                      | 2.1                  |
| 150                      | 2.2                  |
| 200                      | 2.3                  |
| 250                      | 2.4                  |
| 300                      | 2.5                  |
| 400                      | 2.6                  |

Without the CYA correction in our example, you would use a total alkalinity of 100 ppm (AF = 2.0). With the correction, you use an adjusted alkalinity of 80 ppm (AF = 1.9). That 0.1 difference shifts the entire LSI by 0.1, which can be the difference between balanced and corrosive water.

In pools with very high CYA levels, such as 90 ppm or above, the correction becomes even more significant. At a CYA of 90 ppm with a total alkalinity of 100 ppm, the adjusted alkalinity drops to just 70 ppm, producing a substantially lower AF and a lower LSI.

## TDS Constant

The TDS Constant is derived from the Total Dissolved Solids concentration in the pool water. For most swimming pools, the TDS Constant is 12.1 when TDS is in the typical range of 1,000 to 2,000 ppm. For pools with significantly higher TDS, such as saltwater pools where TDS may reach 3,000 to 6,000 ppm, the constant is 12.2.

Because the TDS Constant changes minimally across the range of TDS values found in swimming pools, many practitioners use a fixed value of 12.1 for standard pools and 12.2 for saltwater pools. This simplification introduces negligible error and is widely accepted in the pool industry.

## Interpreting the LSI Value

Once all factors are calculated and the formula is applied, the resulting LSI value falls into one of three ranges:

**LSI below -0.3: Corrosive Water.** The water is undersaturated with calcium carbonate and will aggressively seek to dissolve calcium from any available source. In pools, this means etching and deterioration of plaster and marcite surfaces, pitting and discoloration of concrete, corrosion of metal components including heater heat exchangers, pump impellers, and ladder rails, deterioration of grouting and tile adhesive, and shortened equipment lifespan.

**LSI between -0.3 and +0.3: Balanced Water.** The water is near equilibrium with calcium carbonate. This is the target range for all swimming pools. Water in this range neither aggressively dissolves surfaces nor deposits significant scale. The ideal target is 0.0, with a practical operating range of -0.2 to +0.2 providing a comfortable margin.

**LSI above +0.3: Scale-Forming Water.** The water is oversaturated with calcium carbonate, and the excess will precipitate out of solution as scale. Scale deposits appear as white or gray crusty buildup on pool surfaces, rough texture on tile and plaster, reduced flow through pipes and fittings, scale accumulation on heat exchangers reducing efficiency and potentially causing overheating, and cloudy water when scaling is occurring rapidly.

## Practical LSI Calculation: Worked Examples

### Example 1: A Typical Residential Pool in Summer

**Measured Parameters:**
- pH: 7.5
- Water Temperature: 84 degrees F
- Calcium Hardness: 300 ppm
- Total Alkalinity: 100 ppm
- CYA: 45 ppm
- TDS: 1,500 ppm

**Step 1: Apply CYA Correction**
Adjusted Alkalinity = 100 - (45 / 3) = 100 - 15 = 85 ppm

**Step 2: Look Up Factors**
- pH = 7.5 (direct input)
- TF at 84 degrees F = 0.7
- CF at 300 ppm calcium = 2.1
- AF at 85 ppm adjusted alkalinity = 1.9 (interpolating between 75 and 100 ppm)
- TDS Constant = 12.1

**Step 3: Calculate LSI**
LSI = 7.5 + 0.7 + 2.1 + 1.9 - 12.1 = **+0.1**

**Interpretation:** This pool is in the balanced range with a very slight scale tendency. No corrective action is needed. This is excellent water balance.

### Example 2: The Same Pool in Winter

Now suppose the pool's temperature drops to 53 degrees F and all chemical parameters remain the same.

**Step 1: Apply CYA Correction (unchanged)**
Adjusted Alkalinity = 100 - (45 / 3) = 85 ppm

**Step 2: Look Up Factors**
- pH = 7.5
- TF at 53 degrees F = 0.3
- CF at 300 ppm calcium = 2.1
- AF at 85 ppm adjusted alkalinity = 1.9
- TDS Constant = 12.1

**Step 3: Calculate LSI**
LSI = 7.5 + 0.3 + 2.1 + 1.9 - 12.1 = **-0.3**

**Interpretation:** The pool is now at the edge of the corrosive range. The 0.4 drop in the Temperature Factor (from 0.7 to 0.3) shifted the LSI from +0.1 to -0.3. This pool needs corrective action to prevent surface etching during the cooler months.

### Example 3: Correcting the Winter Pool

To bring the winter pool back to balanced, we can raise the pH, increase alkalinity, or increase calcium hardness. The most practical approach is often to raise the pH slightly and increase alkalinity.

If we raise pH from 7.5 to 7.8 using soda ash (6 ounces per 10,000 gallons per 0.2 pH rise) and increase total alkalinity from 100 to 110 ppm using sodium bicarbonate (24 ounces per 10,000 gallons per 10 ppm increase):

**Recalculated:**
- Adjusted Alkalinity = 110 - (45 / 3) = 110 - 15 = 95 ppm
- pH = 7.8
- TF = 0.3
- CF = 2.1
- AF at 95 ppm = 2.0 (interpolating)
- TDS Constant = 12.1

LSI = 7.8 + 0.3 + 2.1 + 2.0 - 12.1 = **+0.1**

The pool is now back in the balanced range. This example illustrates how technicians can use the LSI proactively to adjust water chemistry ahead of seasonal changes, rather than reacting to surface damage after it occurs.

### Example 4: High CYA Pool Without Correction

Consider a pool where CYA has climbed to 90 ppm due to prolonged use of trichlor tablets:

- pH: 7.4
- Water Temperature: 76 degrees F (TF = 0.6)
- Calcium Hardness: 250 ppm (CF = 2.0)
- Total Alkalinity: 90 ppm
- CYA: 90 ppm
- TDS: 1,800 ppm (TDS Constant = 12.1)

**Without CYA Correction (Incorrect):**
LSI = 7.4 + 0.6 + 2.0 + 2.0 - 12.1 = -0.1 (appears balanced)

**With CYA Correction (Correct):**
Adjusted Alkalinity = 90 - (90 / 3) = 90 - 30 = 60 ppm
AF at 60 ppm = 1.8

LSI = 7.4 + 0.6 + 2.0 + 1.8 - 12.1 = **-0.3**

The corrected LSI reveals that this pool is actually at the edge of the corrosive range, not balanced as the uncorrected calculation suggested. A technician relying on the uncorrected value would leave this pool in a condition where surface etching and equipment corrosion are actively occurring.

## Strategies for LSI Correction

When the LSI falls outside the balanced range, technicians have several adjustment options depending on which direction the correction needs to go.

### Raising the LSI (Correcting Corrosive Water)

To increase the LSI toward zero from a negative value, raise pH by adding soda ash at 6 ounces per 10,000 gallons per 0.2 pH increase, raise total alkalinity by adding sodium bicarbonate at 24 ounces per 10,000 gallons per 10 ppm increase, raise calcium hardness by adding calcium chloride at 20 ounces per 10,000 gallons per 10 ppm increase, or raise water temperature if heating is available and practical.

### Lowering the LSI (Correcting Scale-Forming Water)

To decrease the LSI toward zero from a positive value, lower pH by adding muriatic acid at 26 ounces per 10,000 gallons per 0.2 pH decrease, lower total alkalinity through acid treatment and aeration cycling, lower calcium hardness through partial drain and refill or reverse osmosis treatment, or lower water temperature if cooling is practical.

The choice of which parameter to adjust depends on where each parameter currently sits relative to its individual ideal range. Adjusting a parameter that is already within its ideal range to correct the LSI may solve the saturation index problem while creating other water chemistry issues.

## How PoolFlow Helps

PoolFlow automates the entire LSI calculation process, eliminating the manual factor lookups and arithmetic that make hand-calculated LSI prone to error. When a technician enters test results into the platform, PoolFlow instantly computes the LSI using the complete formula: LSI equals pH plus Temperature Factor plus Calcium Factor plus Alkalinity Factor minus TDS Constant. The CYA correction is applied automatically, calculating adjusted alkalinity as total alkalinity minus CYA divided by three, ensuring accurate results even in pools with elevated stabilizer levels. The platform displays the current LSI value with clear visual indicators showing whether the water is corrosive, balanced, or scale-forming. When correction is needed, PoolFlow calculates the precise chemical dosing required based on the pool's volume, telling technicians exactly how much muriatic acid, soda ash, sodium bicarbonate, or calcium chloride to add. Historical LSI tracking across service visits reveals trends before they become problems, and seasonal alerts help technicians anticipate temperature-driven LSI shifts. For a broader perspective on the water chemistry parameters that feed into the LSI, explore our [complete water balance and chemistry guide](/blog/pool-water-balance-chemistry-guide/).
