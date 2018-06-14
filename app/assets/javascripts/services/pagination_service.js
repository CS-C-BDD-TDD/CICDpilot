app.service('paginationService',function(){
  return {
    first_record: function(offset) {
      if (isNaN(offset)) {
        offset=parseInt(offset);
      }
      return offset+1;
    },

    last_record: function(offset,per_page,total_count) {
      if (isNaN(offset)) {
        offset=parseInt(offset);
      }
      if (isNaN(per_page)) {
        per_page=parseInt(per_page);
      }
      if (isNaN(total_count)) {
        total_count=parseInt(total_count);
      }
      var last=offset+per_page;
      if (last>total_count) {
        last=total_count;
      }
      return last;
    },

    total_pages: function(per_page,total_count) {
      if (isNaN(per_page)) {
        per_page=parseInt(per_page);
      }
      if (isNaN(total_count)) {
        total_count=parseInt(total_count);
      }
      if (total_count) {
        return ((total_count - 1)/per_page>>0) + 1;
      }
      return 0;
    },

    current_page: function(per_page,offset) {
      if (isNaN(per_page)) {
        per_page=parseInt(per_page);
      }
      if (isNaN(offset)) {
        offset=parseInt(offset);
      }
      return (offset/per_page)+1;
    },

    first_page: function(per_page,offset) {
      if (this.current_page(per_page,offset) == 1) {
        return true;
      }
      return false;
    },

    last_page: function(per_page,offset,total_count) {
      if (this.current_page(per_page,offset) == this.total_pages(per_page,total_count)) {
        return true;
      }
      return false;
    },

    previous_page: function(per_page,offset) {
      if (!this.first_page(per_page,offset)) {
        return this.current_page(per_page,offset) - 1;
      }
      return null;
    },

    next_page: function(per_page,offset,total_count) {
      if (!this.last_page(per_page,offset,total_count)) {
        return this.current_page(per_page,offset) + 1;
      }
      return null;
    },

    out_of_bounds: function(per_page,offset,total_count) {
      var cur_page = this.current_page(per_page,offset);
      if (cur_page > this.total_pages(per_page,total_count) || cur_page < 1) {
        return true;
      }
      return false;
    }
  };
});
