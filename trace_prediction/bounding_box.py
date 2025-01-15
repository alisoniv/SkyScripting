class BoundingBox:
    def __init__(self, rows, cols):
        self.initial_rows = rows
        self.initial_cols = cols 
        self.padding = 20
        self.reset()
    
    def add_point(self, point):
        x, y = point
        if y < self.top:
            self.top = y

        if y > self.bottom:
            self.bottom = y

        if x > self.right:
            self.right = x
        
        if x < self.left:
            self.left = x

    def get_top_bound(self):
        return self.top - self.padding

    def get_bottom_bound(self):
        return self.bottom + self.padding
    
    def get_left_bound(self):
        return self.left - self.padding
    
    def get_right_bound(self):
        return self.right + self.padding

    def reset(self):
        self.top = self.initial_rows
        self.bottom = 0
        self.right = 0
        self.left = self.initial_cols