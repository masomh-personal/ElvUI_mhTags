# ElvUI_mhTags v5.0.0 Optimization Notes

## Memory Optimization Changes

### Key Optimizations Made:

#### 1. **Removed Complex Caching Mechanisms**

- Eliminated FORMAT_PATTERNS caching that was creating persistent string references
- Replaced with direct formatting using common patterns (%.0f, %.1f, etc.)
- This prevents memory accumulation from cached format strings

#### 2. **Simplified Gradient Table Generation**

- Reduced complexity of gradient interpolation algorithm
- Removed unnecessary color stop calculations
- Direct calculation for red->yellow->green transitions
- Single table creation at load time (101 entries only)

#### 3. **Eliminated Pre-allocated Variables**

- Removed module-level variable pre-allocation that could cause state issues
- All variables now locally scoped within functions
- Prevents potential memory leaks from persistent references

#### 4. **Optimized String Operations**

- Replaced complex string concatenation with table.concat where appropriate
- Removed unnecessary string caching (EMPTY_STRING, format patterns)
- Direct formatting for common cases (0-2 decimal places)

#### 5. **Streamlined Helper Functions**

- Removed unused functions (hexToRgb, includes)
- Simplified abbreviation function to use fewer intermediate tables
- Optimized classification formatting without function tables

#### 6. **Reduced API Call Overhead**

- Variables defined locally in functions to avoid redundant calls
- Early returns for common cases (full health, zero power)
- Optimized condition ordering (most common cases first)

## Performance Best Practices Applied:

### String Handling:

- Use direct format strings for common cases
- Avoid creating intermediate string variables
- Use table.concat for multi-part string building

### Memory Management:

- No module-level variable reuse (prevents concurrent call issues)
- Local variables scoped to functions
- Minimal table allocations

### Tag Update Frequency:

- Multiple throttle options (0.25s, 0.5s, 1.0s, 2.0s)
- Use appropriate throttle for each tag based on importance
- Raid frames should use higher throttle values (1.0s+)

## Recommended Usage:

### For Raid Frames (40+ units):

- Use throttled tags (-1.0 or -2.0 suffix)
- Example: `[mh-health-current-percent-hidefull-1.0]`

### For Party/Arena (5-10 units):

- Can use faster updates (-0.5 suffix)
- Example: `[mh-health-deficit:status-0.5]`

### For Player/Target (1-2 units):

- Can use fastest updates (-0.25 or no suffix)
- Example: `[mh-health-current-percent:gradient-colored]`

## Memory Usage Guidelines:

The addon should maintain stable memory usage:

- Initial load: ~100-200 KB
- After 1 minute: < 500 KB
- Stable state: < 1 MB

If memory grows beyond these limits, check for:

1. Too many unthrottled tags on raid frames
2. Custom modifications creating closures
3. Other addons interfering with ElvUI's tag system

## Testing Recommendations:

1. Monitor memory with: `/run print(GetAddOnMemoryUsage("ElvUI_mhTags"))`
2. Test in raid environment with 40 frames visible
3. Verify no memory growth over 5-minute period
4. Check CPU usage with: `/run print(GetAddOnCPUUsage("ElvUI_mhTags"))`

## Version History:

### v5.0.0 (Current)

- Complete optimization overhaul
- Removed complex caching systems
- Simplified all core functions
- Fixed memory leak issues from v4.x

### Previous Issues (v4.x):

- Complex caching created memory leaks
- Pre-allocated variables caused state issues
- Format pattern caching accumulated memory
- Function tables created unnecessary closures
