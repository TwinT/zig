pub fn isLeapYear(year: u32) bool {
    if ((year % 4) == 0) {
        if (year % 400 == 0) {
            return true;
        }
        if (year % 100 == 0) {
            return false;
        }
        return true;
    }
    return false;
}
